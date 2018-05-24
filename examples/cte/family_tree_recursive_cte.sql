WITH RECURSIVE dump_family AS (
    -- parte non ricorsiva: figlio
    SELECT *,
    'FIGLIO' AS description
    FROM family_tree
    WHERE parent_of IS NULL
 UNION
    -- parte ricorsiva: join dei genitori
    SELECT f.*,
    'GENITORE di ' || df.name AS description
    FROM dump_family df
    JOIN family_tree f ON f.parent_of = df.pk
)

-- query finale
SELECT name, description FROM dump_family;
