@lexer lexer
@include "base.ne"
@include "expr.ne"


select_statement
    -> select_what _ select_from:? _ select_where:? {% ([columns, _, from, __, where]) => {
        from = unwrap(from);
        return {
            columns,
            ...from ? { from: [from] } : {},
            where,
            type: 'select',
        }
    } %}

select_statement_paren -> lparen _ select_statement _ rparen {% get(2) %}

# FROM [subject] [alias?]
select_from -> %kw_from _ select_subject {% last %}

# Table name or another select statement wrapped in parens
select_subject
    -> table_ref_aliased {% x => ({ type: 'table', ...x[0]}) %}
    | select_subject_select_statement

# Selects on subselects MUST have an alias
select_subject_select_statement -> select_statement_paren _ ident_aliased {% x => ({
    type: 'statement',
    statement: unwrap(x[0]),
    alias: unwrap(x[2])
}) %}


# SELECT x,y as YY,z
select_what -> %kw_select _ select_expr_list_aliased {% last %}

select_expr_list_aliased -> select_expr_list_item (_ comma _ select_expr_list_item {% last %}):* {% ([head, tail]) => {
    return [head, ...(tail || [])];
} %}

select_expr_list_item -> expr (_ ident_aliased {% last %}):? {% x => ({
    expr: x[0],
    ...x[1] ? {alias: unwrap(x[1]) } : {},
}) %}

# WHERE [expr]
select_where -> %kw_where _ expr {% last %}