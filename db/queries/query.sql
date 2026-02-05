-- name: GetCategory :one
SELECT * FROM categories
WHERE id = $1 LIMIT 1;
