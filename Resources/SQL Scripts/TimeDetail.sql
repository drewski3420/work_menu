IF object_Id('tempdb..#d') IS NOT NULL BEGIN DROP TABLE #d END
IF object_Id('tempdb..#nines') IS NOT NULL BEGIN DROP TABLE #nines end

DECLARE	@totalTimeToAdd int 
CREATE TABLE #d (
		ID int
		,name nvarchar(MAX)
		,units float
		,Total float
		,PortPerc float
		,PercentWOGNMA float
		,GrossTime nvarchar(MAX)
		,Mins int
		,RowNum int
)

--get totals
INSERT	INTO #d (ID,name,units,Total,PortPerc,PercentWOGNMA,GrossTime)
EXEC RPT101.investor.time_dist_by_investor 8, 0, 8, 0, 0

--fix goldman and first key
UPDATE #d
SET ID =	CASE name
				WHEN 'MTGLQ Investors, LP'			THEN 527
				WHEN 'New Jersey Community Capital' THEN 528
				WHEN 'Atlantica LLC'				THEN 529
				WHEN 'First Key'					THEN 530
				WHEN 'Freddie Mac'					THEN 211
				WHEN 'Athene'						THEN 531
				WHEN 'Nomura'						THEN 523
				ELSE ID
			END

--update minutes int column for adding later
UPDATE d
SET	d.Mins = dateDiff(MINUTE, 0, cast(d.GrossTime AS time))
FROM #d d

--get rid of items we don't need
SELECT *
INTO #nines
FROM #d
WHERE 1=1
	AND ID = 999

DELETE #d
WHERE 1 = 0
	OR ID = 999
	OR GrossTime = '0:00'

--add a rownum for updating later
UPDATE d
SET	d.RowNum = a.RowNum
FROM #d d
	INNER JOIN (
		SELECT
			d1.ID
			,RowNum = row_Number() OVER (ORDER BY cast(d1.GrossTime AS time) DESC)
		FROM #d d1
	) a ON a.ID = d.ID

--get total time needed added back or subtracted (rounding)
SELECT @totalTimeToAdd = (480 - sum(dateDiff(MINUTE, 0, cast(GrossTime AS datetime))))
FROM #d

--update mins to add minutes so that total day equals 8 hours
UPDATE d
SET	d.Mins = d.Mins + sign(@totalTimeToAdd) * CASE WHEN abs(@totalTimeToAdd) >= d.RowNum THEN 1 ELSE 0 END
FROM #d d

SELECT
	ID = cast(ID AS nvarchar(MAX))
	,H = right('00' + cast(Mins / 60 AS nvarchar(MAX)),2)
	,M = right('00' + cast(Mins % 60 AS nvarchar(MAX)),2)
	,so = 0
FROM #d
UNION ALL
SELECT 
	ID = ''
	,H = 'Missing'
	,M = name
	,so = 1
FROM #nines
ORDER BY
	4
	,2 DESC
	,3 DESC
	,1