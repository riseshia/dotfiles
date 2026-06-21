# SQL / Query Checklist

## Report

- SQL injection via string interpolation or concatenation with user input.
- Wrong boolean logic in WHERE conditions (AND/OR precedence, negation errors).
- Missing JOIN conditions producing unintended cartesian products.
- Full-table scan risk from a newly added query on a large table without an index hint or WHERE clause.
- Large unbounded query without LIMIT/pagination.
- N+1 query pattern: query inside a loop.
- For MyBatis: unsafe `${}` interpolation where `#{}` parameter binding should be used.

## Do NOT report

- `${}` in MyBatis when used for table/column names (legitimate dynamic SQL).
- Query style preferences (subquery vs JOIN) unless one is clearly incorrect.
- Missing indexes unless the query pattern and table size make it a clear performance issue.
