{
  "$dyn" = fun l t => t,

  "$num" = fun l t => if %is_num% t then t else %blame% l,

  "$bool" = fun l t => if %is_bool% t then t else %blame% l,

  "$string" = fun l t => if %is_str% t then t else %blame% l,

  "$fail" = fun l t => %blame% l,

  "$array" = fun elt l t =>
    if %is_array% t then
      %map% t (fun value => %assume% elt (%go_array% l) value)
    else %blame% l,

  "$func" = fun s t l e =>
      if %is_fun% e then
          (fun x => %assume% t (%go_codom% l) (e (%assume% s (%chng_pol% (%go_dom% l)) x)))
      else
          %blame% l,

  "$forall_var" = fun sy pol l t =>
      let lPol = %polarity% l in
      if pol == lPol then
          %unwrap% sy t (%blame% l)
      else
          %wrap% sy t,

  "$row_extend" = fun contr case l t =>
      if (case t) then
          t
      else
          %assume% contr l t,

  "$record" = fun cont l t =>
      if %is_record% t then
          %assume% (cont {}) l t
      else
          %blame% (%tag% "not a record" l),

  "$dyn_record" = fun contr l t =>
      if %is_record% t then
          %record_map% t (fun _field value => %assume% contr l value)
      else
          %blame% (%tag% "not a record" l),

  "$record_extend" = fun field contr cont acc l t =>
      if %has_field% field t then
          let acc = %record_insert%
            field
            acc
            (%assume% contr (%go_field% field l) (t."%{field}")) in
          let t = %record_remove% field t in
          cont acc l t
      else
          %blame% (%tag% "missing field `%{field}`" l),

  "$forall_tail" = fun sy pol acc l t =>
      let magic_fld = "_%wrapped" in
      if pol == (%polarity% l) then
          if %has_field% magic_fld t then
              let rest = %record_remove% magic_fld t in
              if rest == {} then
                  let fail = %blame% (%tag% "polymorphic tail mismatch" l) in
                  let inner = %unwrap% sy (t."%{magic_fld}") fail in
                  acc & inner
              else
                  %blame% (%tag% "extra field `%{%head% (%fields% rest)}`" l)
          else
              %blame% (%tag% "missing polymorphic part" l)
      else
          %record_insert% magic_fld acc (%wrap% sy t),

  "$dyn_tail" = fun acc l t => acc & t,

  "$empty_tail" = fun acc l t =>
      if t == {} then acc
      else %blame% (%tag% "extra field `%{%head% (%fields% t)}`" l),

  contract = {
    blame
      | doc m%"
        Raise blame for a given label.

        Type: `forall a. Lbl -> a`
        (for technical reasons, this element isn't actually statically typed)

        Blame is the mechanism to signal contract violiation in Nickel. It ends
        the program execution and print a detailed report thanks to the
        information tracked inside the label.

        For example:
        ```nickel
        IsZero = fun label value =>
          if value == 0 then value
          else contract.blame label
        ```
        "%m
      = fun l => %blame% l,

    blame_with
      | doc m%"
        Raise blame with respect to a given label and a custom error message.

        Type: `forall a. Str -> Lbl -> a`
        (for technical reasons, this element isn't actually statically typed)

        Same as `blame`, but take an additional custom error message that will be
        displayed as part of the blame error. `blame_with msg l` is equivalent to
        `blame (tag msg l)

        For example:
        ```nickel
        let IsZero = fun label value =>
          if value == 0 then value
          else contract.blame_with "Not zero" label in
        0 | IsZero
        ```
        "%m
      = fun msg l => %blame% (%tag% msg l),

    from_predicate
      | doc m%"
        Generate a contract from a boolean predicate.

        Type: `(Dyn -> Bool) -> (Lbl -> Dyn -> Dyn)`
        (for technical reasons, this element isn't actually statically typed)

        For example:
        ```
        let IsZero = contract.from_predicate (fun x => x == 0) in
        0 | IsZero
        ```
        "%m
      = fun pred l v => if pred v then v else %blame% l,

    tag
      | doc m%"
        Attach a tag, or a custom error message, to a label. If a tag was
        previously set, it is erased.

        Type: `Str -> Lbl -> Lbl`
        (for technical reasons, this element isn't actually statically typed)

        For example:
        ```
        let ContractNum = contract.from_predicate (fun x => x > 0 && x < 50) in
        Contract = fun label value =>
          if builtin.is_num value then
            ContractNum
              (contract.tag "num subcontract failed! (out of bound)" label)
              value
          else
            value in
        5 | Contract
        ```
        "%m
      = fun msg l => %tag% msg l,

    apply
      | doc m%"
        Apply a contract to a label and a value.

        Type: `Contract -> Lbl -> Dyn -> Dyn`
        (for technical reasons, this element isn't actually statically typed)

        Nickel supports user-defined contracts defined as functions, but also as
        records. Moreover, the interpreter performs additional book-keeping for
        error reporting when applying a contract in an expression `value |
        Contract`. You should not use standard function application to apply a
        contract, but this function instead.

        For example:
        ```
        let Nullable = fun param_contract label value =>
          if value == null then null
          else contract.apply param_contract label value
        in
        let Contract = Nullable {foo | Num} in
        ({foo = 1} | Contract)
        ```
        "%m
      = fun contract label value => %assume% contract label value,
  },
}
