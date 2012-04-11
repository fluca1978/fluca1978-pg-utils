CREATE OR REPLACE VIEW vw_magtitles
AS
SELECT title, download_path
FROM   magazine
ORDER  BY issuedon;