defmodule Exdns.Resolver do
  require Record
  require Logger
  require Exdns.Records

  def resolve(message, authority, host) do
    case Exdns.Records.dns_message(message, :questions) do
      [] -> message
      [question] -> resolve(message, authority, host, question)
      [question|_] -> resolve(message, authority, host, question)
    end
  end

  # Resolution process

  # Step 1 - Set the RA bit to false as we do not handle recursive queries.
  def resolve(message, authority, host, question) do
    check_dnssec(message, host, question)
    resolve(Exdns.Records.dns_message(message, ra: false, ad: false), authority, Exdns.Records.dns_query(question, :name), Exdns.Records.dns_query(question, :type), host)
  end

  # Step 2: Search the available zones for the zone which is the nearest ancestor to qname
  # With the qname and qtype in hand, find the nearest zone.
  def resolve(message, authority, qname, qtype, host) do
    zone = Exdns.ZoneCache.find_zone(qname, authority)
    message = resolve(message, qname, qtype, zone, host, _cname_chain = [])
    rewrite_soa_ttl(message) |> additional_processing(host, zone)
  end

  # Step 3: Match records
  # If no SOA was found, return a no error result.
  # If an SOA is found then start the resolution to match the appropriate records.
  def resolve(message, _, _, {:error, :not_authoritative}, _, _) do
    if Exdns.Config.use_root_hints() do
      {authority, additional} = Exdns.Records.root_hints()
      Exdns.Records.dns_message(message, aa: true, rc: :dns_terms_const.dns_rcode_noerror, authority: authority, additional: additional)
    else
      Exdns.Records.dns_message(message, aa: true, rc: :dns_terms_const.dns_rcode_noerror)
    end
  end
  def resolve(message, qname, qtype, zone, host, cname_chain) do
    case Enum.dedup(Exdns.ZoneCache.get_records_by_name(qname)) do
      [] ->
        Logger.debug("No exact match by name, using best match resolution")
        best_match_resolution(message, qname, qtype, host, cname_chain, best_match(qname, zone), zone)
      matched_records ->
        Logger.debug("Exact match by name, using exact match resolution")
        exact_match_resolution(message, qname, qtype, host, cname_chain, matched_records, zone)
    end
  end

  # Exact match resolution logic
  # 
  # Functions in this section are used when there is at least one record that matches
  # the qname exactly.

  # Determine if there is a CNAME anywhere in the records with the given qname.
  def exact_match_resolution(message, qname, qtype, host, cname_chain, matched_records, zone) do
    case Enum.filter(matched_records, Exdns.Records.match_type(:dns_terms_const.dns_type_cname)) do
      [] ->
        Logger.debug("Found no CNAME records with the given qname")
        resolve_exact_match(message, qname, qtype, host, cname_chain, matched_records, zone)
      cname_records ->
        Logger.debug("Found CNAME records with given qname")
        resolve_exact_match_with_cname(message, qtype, host, cname_chain, matched_records, zone, cname_records)
    end
  end

  # There were no CNAMEs found in the exact name matches, so now grab the authority records
  # and find any type matches on qtype and continue.
  def resolve_exact_match(message, qname, qtype, host, cname_chain, matched_records, zone) do
    authority_records = Enum.filter(matched_records, Exdns.Records.match_type(:dns_terms_const.dns_type_soa))
    any_type = :dns_terms_const.dns_type_any
    type_matches = case qtype do
      ^any_type -> filter_records(matched_records, Exdns.Handler.Registry.get_handlers())
      _ -> Enum.filter(matched_records, Exdns.Records.match_type(qtype))
    end
    case type_matches do
      [] ->
        Logger.debug("Found no type matches")
        records = List.flatten(Enum.map(Exdns.Handler.Registry.get_handlers(), custom_lookup(qname, qtype, matched_records)))
        resolve_exact_match(message, qname, qtype, host, cname_chain, matched_records, zone, records, authority_records)
      _ ->
        Logger.debug("Found type matches")
        resolve_exact_match(message, qname, qtype, host, cname_chain, matched_records, zone, type_matches, authority_records)
    end
  end

  def resolve_exact_match(message, qname, qtype, host, cname_chain, matched_records, zone, exact_type_matches, authority_records) do
    case exact_type_matches do
      [] ->
        referral_records = Enum.filter(matched_records, Exdns.Records.match_type(:dns_terms_const.dns_type_ns))
        resolve_no_exact_type_match(message, qtype, host, cname_chain, [], zone, matched_records, referral_records, authority_records)
      _ ->
        resolve_exact_type_match(message, qname, qtype, host, cname_chain, exact_type_matches, zone, authority_records)
    end
  end

  # There is at least one RR present in the zone that matches the qtype
  def resolve_exact_type_match(message, qname, qtype, host, cname_chain, matched_records, zone, authority_records) do
    ns_type = :dns_terms_const.dns_type_ns
    case qtype do
      ^ns_type ->
        case authority_records do
          [] ->
            # Exact type match for NS query, but there is no SOA for the zone
            name = Exdns.Records.dns_rr(List.last(matched_records), :name)
            # It isn't clear what the qtype should be on a delegated start, so I assume an A record
            restart_delegated_query(message, name, :dns_terms_const.dns_type_a, host, cname_chain, zone, Exdns.ZoneCache.in_zone?(name))
          _ ->
            # Exact type match for NS query and there is an SOA records.
            answers = Exdns.Records.dns_message(message, :answers) ++ matched_records
            Exdns.Records.dns_message(message, aa: true, rc: :dns_terms_const.dns_rcode_noerror, answers: answers)
        end
      _ ->
        # Exact type match for something other than an NS record and the SOA is present
        answer = List.last(matched_records)
        case ns_records = Exdns.ZoneCache.get_delegations(Exdns.Records.dns_rr(answer, :name)) do
          [] ->
            resolve_exact_type_match(message, qname, qtype, host, cname_chain, matched_records, zone, authority_records, ns_records = [])
          _ ->
            ns_record = List.last(ns_records)
            case Exdns.ZoneCache.get_authority(qname) do
              {:ok, soa_record} ->
                if Exdns.Records.dns_rr(soa_record, :name) == Exdns.Records.dns_rr(ns_record, :name) do
                  answers = merge_with_answers(message, matched_records)
                  Exdns.Records.dns_message(message, aa: true, rc: :dns_terms_const.dns_rcode_noerror, answers: answers)
                else
                  resolve_exact_type_match(message, qname, qtype, host, cname_chain, matched_records, zone, authority_records, ns_records)
                end
            end
        end
    end
  end


  # We are authoritative and there are no NS records here
  def resolve_exact_type_match(message, qname, qtype, host, cname_chain, matched_records, zone, authority_records, []) do
    Logger.debug("Resolved exact type match and there are no NS records: #{inspect matched_records}")
    dm(Exdns.Records.dns_message(message, aa: true, rc: :dns_terms_const.dns_rcode_noerror, answers: merge_with_answers(message, matched_records)))
  end
  # We are authoritative and there are NS records here
  def resolve_exact_type_match(message, qname, qtype, host, cname_chain, matched_records, zone, authority_records, ns_records) do
    Logger.debug("Resolved exact type match and there are NS records")
    # NOTE: there is a potential bug here because it assumes the last record is the one to examine
    answer = List.last(matched_records)
    ns_record = List.last(ns_records)
    name = Exdns.Records.dns_rr(ns_record, :name)
    if name == Exdns.Records.dns_rr(answer, :name) do
      Exdns.Records.dns_message(message, aa: false, rc: :dns_terms_const.dns_rcode_noerror, authority: merge_with_authority(message, ns_records))
    else
      # TODO: only restart delegation if the NS record is on a parent node
      # if it is a sibling then we should not restart
      if parent?(name, Exdns.Records.dns_rr(answer, :name)) do
        restart_delegated_query(message, name, qtype, host, cname_chain, zone, Exdns.ZoneCache.in_zone?(name))
      else
        Exdns.Records.dns_message(message, aa: true, rc: :dns_terms_const.dns_rcode_noerror, answers: merge_with_answers(message, matched_records))
      end
    end
  end


  def parent?(possible_parent_name, name) do
    case :dns.dname_to_labels(possible_parent_name) -- :dns.dname_to_labels(name) do
      [] -> true
      _ -> false
    end
  end


  def resolve_no_exact_type_match(message, qtype, host, cname_chain, exact_type_matches, zone, matched_records, referral_records, authority_records) do
    any_type = :dns_terms_const.dns_type_any
    case qtype do
      ^any_type -> Exdns.Records.dns_message(message, aa: true, authority: authority_records)
      _ ->
        case {referral_records, exact_type_matches} do
          {[], []} -> Exdns.Records.dns_message(message, aa: true, authority: [zone.authority])
          {[], _} -> Exdns.Records.dns_message(message, aa: true, answers: merge_with_answers(message, exact_type_matches))
          {_, _} -> resolve_exact_match_referral(message, qtype, matched_records, referral_records, authority_records)
        end
    end
  end


  # Given an exact name match where the qtype is not found in the record set, and we are not authoritative,
  # add the NS records to the authority section of the message.
  def resolve_exact_match_referral(message, qtype, matched_records, referral_records, []) do
    Exdns.Records.dns_message(message, authority: merge_with_authority(message, referral_records))
  end
  def resolve_exact_match_referral(message, qtype, matched_records, referral_records, authority_records) do
    any_type = :dns_terms_const.dns_type_any
    ns_type = :dns_terms_const.dns_type_ns
    soa_type = :dns_terms_const.dns_type_soa

    case qtype do
      ^any_type -> Exdns.Records.dns_message(message, aa: true, answers: matched_records)
      ^ns_type -> Exdns.Records.dns_message(message, aa: true, answers: referral_records)
      ^soa_type -> Exdns.Records.dns_message(message, aa: true, answers: authority_records)
      _ -> Exdns.Records.dns_message(message, aa: true, rc: :dns_terms_const.dns_rcode_noerror, authority: authority_records)
    end
  end


  def resolve_exact_match_with_cname(message, qtype, host, cname_chain, matched_records, zone, cname_records) do
    cname_type = :dns_terms_const.dns_type_cname
    case qtype do
      ^cname_type ->
        Logger.debug("Qtype is CNAME, returning the CNAME records: #{inspect cname_records}")
        Exdns.Records.dns_message(message, aa: true, answers: merge_with_answers(message, cname_records))
      _ ->
        if Enum.member?(cname_chain, List.last(cname_records)) do
          Exdns.Records.dns_message(message, aa: true, rc: :dns_terms_const.dns_rcode_servfail) # CNAME loop
        else
          name = Exdns.Records.dns_rr(List.last(cname_records), :data) |> Exdns.Records.dns_rrdata_cname(:dname)
          restart_query(Exdns.Records.dns_message(message, aa: true, answers: Exdns.Records.dns_message(message, :answers) ++ cname_records), name, qtype, host, cname_chain ++ cname_records, zone, Exdns.ZoneCache.in_zone?(name))
        end
    end
  end


  def restart_query(message, name, qtype, host, cname_chain, zone, in_zone) do
    if in_zone do
      # The CNAME is in the zone so we do not need to look it up again.
      resolve(message, name, qtype, zone, host, cname_chain)
    else
      # The CNAME is not in the zone so we need to find the zone using the CNAME content
      resolve(message, name, qtype, Exdns.ZoneCache.find_zone(name), host, cname_chain)
    end
  end


  def restart_delegated_query(message, name, qtype, host, cname_chain, zone, in_zone) do
    if in_zone do
      resolve(message, name, qtype, zone, host, cname_chain)
    else
      resolve(message, name, qtype, Exdns.ZoneCache.find_zone(name, zone.authority), host, cname_chain)
    end
  end

  # Best meatch resolution logic
  #
  # Functions in this section are used when there is no exact match for the given qname.
  # Best match looks for wildcard records that match.

  # There was no match for the qname, so we use the best matches found.
  # If there are no NS records in the matches then this is not a referral.
  # If there are NS records in the best matches this is a referral.
  def best_match_resolution(message, qname, qtype, host, cname_chain, best_match_records, zone) do
    referral_records = Enum.filter(best_match_records, Exdns.Records.match_type(:dns_terms_const.dns_type_ns)) # NS lookup
    case referral_records do
      [] -> resolve_best_match(message, qname, qtype, host, cname_chain, best_match_records, zone)
      _ -> resolve_best_match_referral(message, qname, qtype, host, cname_chain, best_match_records, zone, referral_records)
    end
  end

  # There was no referral present, so check to see if there is a wildcard.
  # If there is a wildcard, then continue resolution with the wildcard.
  # If there is no wildcard then the result is NXDOMAIN.
  def resolve_best_match(message, qname, qtype, host, cname_chain, best_match_records, zone) do
    Logger.debug("No referral present, trying wildcard")
    if Enum.any?(best_match_records, Exdns.Records.match_wildcard) do
      cname_records =
        Enum.map(best_match_records, Exdns.Records.replace_name(qname)) |>
        Enum.filter(Exdns.Records.match_type(:dns_terms_const.dns_type_cname))
      resolve_best_match_with_wildcard(message, qname, qtype, host, cname_chain, best_match_records, zone, cname_records)
    else
      [q|_] = Exdns.Records.dns_message(message, :questions)
      if qname == Exdns.Records.dns_query(q, :name) do
        Exdns.Records.dns_message(message, aa: true, rc: :dns_terms_const.dns_rcode_nxdomain, authority: [zone.authority])
      else
        # This happens when we have a CNAME to an out-of-balliwick hostname and the query is for
        # something other than CNAME. Note that the response is still NOERROR error.
        #
        # In the dnstest suite, this is tested by cname_to_unauth_any (and others)
        if Exdns.Config.use_root_hints() do
          {authority, additional} = Exdns.Records.root_hints()
          Exdns.Records.dns_message(message, aa: true, rc: :dns_terms_const.dns_rcode_noerror, authority: authority, additional: additional)
        else
          message
        end
      end
    end
  end


  def resolve_best_match_with_wildcard(message, qname, qtype, host, cname_chain, matched_records, zone, cname_records) do
    Logger.debug("Resolving best match with wildcard")
    case cname_records do
      [] ->
        Logger.debug("No CNAME records, checking for type matches in #{inspect matched_records}")
        records = type_match_records(matched_records, qtype)
        Logger.debug("Type match records: #{inspect records}")
        type_matches = Enum.map(records, Exdns.Records.replace_name(qname))
        Logger.debug("Type matches: #{inspect type_matches}")
        case type_matches do
          [] ->
            # Ask custom handlers for their records
            records =
              Exdns.Handler.Registry.get_handlers() |>
              Enum.map(custom_lookup(qname, qtype, matched_records)) |>
              List.flatten |>
              Enum.map(Exdns.Records.replace_name(qname))
            resolve_best_match_with_wildcard(message, qname, qtype, host, cname_chain, matched_records, zone, [], records)
          _ ->
            resolve_best_match_with_wildcard(message, qname, qtype, host, cname_chain, matched_records, zone, [], type_matches)
        end
      _ ->
        resolve_best_match_with_wildcard_cname(message, qname, qtype, host, cname_chain, matched_records, zone, cname_records)
    end
  end
  def resolve_best_match_with_wildcard(message, qname, qtype, host, cname_chain, best_match_records, zone, [], []) do
    Exdns.Records.dns_message(message, aa: true, authority: [zone.authority])
  end
  def resolve_best_match_with_wildcard(message, qname, qtype, host, cname_chain, best_match_records, zone, [], type_matches) do
    Exdns.Records.dns_message(message, aa: true, answers: merge_with_answers(message, type_matches))
  end


  def resolve_best_match_with_wildcard_cname(message, qname, qtype, host, cname_chain, best_match_records, zone, cname_records) do
    cname_type = :dns_terms_const.dns_type_cname
    case qtype do
      ^cname_type ->
        Exdns.Records.dns_message(message, aa: true, answers: merge_with_answers(message, cname_records))
      _ ->
        # There should only be one CNAME, Multiple CNAMEs kill unicorns.
        cname_record = List.last(cname_records)
        if Enum.member?(cname_chain, cname_record) do
          Exdns.Records.dns_message(message, aa: true, rc: :dns_terms_const.dns_rcode_servfail)
        else
          name = Exdns.Records.dns_rr(cname_record, :data) |> Exdns.Records.dns_rrdata_cname(:dname)
          Exdns.Records.dns_message(message, aa: true, answers: merge_with_answers(message, cname_records)) |>
            restart_query(name, qtype, host, cname_chain ++ cname_records, zone, Exdns.ZoneCache.in_zone?(name))
        end
    end
  end


  # There are referral records present.
  #
  # If there are no SOA records present then we indicate we are not authoritivate for the name.
  # If there is an SOA record then we authoritative for the name
  def resolve_best_match_referral(message, qname, qtype, host, cname_chain, best_match_records, zone, referral_records) do
    authority = Enum.filter(best_match_records, Exdns.Records.match_type(:dns_terms_const.dns_type_soa))
    if qtype == :dns_terms_const.dns_type_any do
      Exdns.Records.dns_message(message, aa: true, rc: :dns_terms_const.dns_rcode_nxdomain, authority: authority)
    else
      case {cname_chain, authority} do
        {_, []} ->
          Exdns.Records.dns_message(message, aa: false, authority: merge_with_authority(message, referral_records))
        {[], _} ->
          Exdns.Records.dns_message(message, aa: true, rc: :dns_terms_const.dns_rcode_nxdomain, authority: authority)
        {_, _} ->
          Exdns.Records.dns_message(message, authority: authority)
      end
    end
  end


  def best_match(qname, zone), do: best_match(qname, :dns.dname_to_labels(qname), zone)

  # No labels
  def best_match(_, [], _), do: []
  # Wildcard
  def best_match(qname, [_|rest], zone) do
    best_match(qname, rest, zone, Exdns.ZoneCache.get_records_by_name(:dns.labels_to_dname(["*"] ++ rest)))
  end

  # No labels, no wildcard name
  def best_match(_, [], _, []), do: []
  # Labels, no wildcard name
  def best_match(qname, labels, zone, []) do
   case Exdns.ZoneCache.get_records_by_name(:dns.labels_to_dname(labels)) do
      [] -> best_match(qname, labels, zone)
      matches -> matches
    end
  end
   # No labels, wildcard name
  def best_match(_, _, _, wildcard_matches), do: wildcard_matches


  def custom_lookup(qname, qtype, records) do
    fn({module, types}) ->
      if Lists.member?(types, qtype) || qtype == :dns_terms_const.dns_type_any  do
        module.handle(qname, qtype, records)
      else
        []
      end
    end
  end


  def type_match_records(records, qtype) do
    any_type = :dns_terms_const.dns_type_any
    case qtype do
      ^any_type -> filter_records(records, Exdns.Handler.Registry.get_handlers())
      _ -> Enum.filter(records, Exdns.Records.match_type(qtype))
    end
  end


  def filter_records(records, []), do: records
  def filter_records(records, [{handler, _}|rest]), do: filter_records(handler.filter(records), rest)


  def rewrite_soa_ttl(message), do: rewrite_soa_ttl(message, Exdns.Records.dns_message(message, :authority), [])
  def rewrite_soa_ttl(message, [], new_authority), do: Exdns.Records.dns_message(message, authority: new_authority)
  def rewrite_soa_ttl(message, [r|rest], new_authority) do
    rewrite_soa_ttl(message, rest, new_authority ++ [Exdns.Records.minimum_soa_ttl(r, Exdns.Records.dns_rr(r, :data))])
  end


  def additional_processing(message, _host, {:error, _}), do: message
  def additional_processing(message, host, zone) do
    record_names = merge_with_answers(message, Exdns.Records.dns_message(message, :authority)) |> requires_additional_processing([]) |> List.flatten
    case record_names do
      [] -> message
      _ ->
        records = Enum.map(record_names, fn(name) -> Exdns.ZoneCache.get_records_by_name(name) end) |>
          List.flatten |>
          Enum.filter(Exdns.Records.match_types([:dns_terms_const.dns_type_a, :dns_terms_const.dns_type_aaaa]))
        case records do
          [] -> message
          _ -> Exdns.Records.dns_message(message, additional: merge_with_additional(message, records))
        end
    end
  end


  def requires_additional_processing([], requires_additional), do: requires_additional
  def requires_additional_processing([answer|rest], requires_additional) do
    names = case Exdns.Records.dns_rr(answer, :data) do
      data when Record.is_record(data, :dns_rrdata_ns) -> [Exdns.Records.dns_rrdata_ns(data, :dname)]
      data when Record.is_record(data, :dns_rrdata_mx) -> [Exdns.Records.dns_rrdata_mx(data, :exchange)]
      _ -> []
    end
    requires_additional_processing(rest, requires_additional ++ names)
  end


  def check_dnssec(message, host, question) do
    false
  end


  # Merges the given `records` with the answers in the given `message` and returns
  # a collection of records.
  defp merge_with_answers(message, records) do
    Exdns.Records.dns_message(message, :answers) ++ records
  end

  defp merge_with_additional(message, records) do
    Exdns.Records.dns_message(message, :additional) ++ records
  end

  defp merge_with_authority(message, records) do
    Exdns.Records.dns_message(message, :authority) ++ records
  end


  defp dm(message) do
    Logger.debug("Message: #{inspect message}")
    message
  end

end
