%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Readability.ModuleAttributeNames, false},
        # {Credo.Check.Design.TagTODO, false}
      ]
    }
  ]
}
