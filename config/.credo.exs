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
        {Credo.Check.Design.TagTODO, false},
        {Credo.Check.Refactor.Nesting, max_nesting: 4},
        {Credo.Check.Refactor.FunctionArity, max_arity: 12}
      ]
    }
  ]
}
