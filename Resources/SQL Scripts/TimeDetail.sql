CREATE table #d (
	ID int 
	,name nvarchar(max)
	,units float
	,Total float
	,PortPerc float
	,PercentWOGNMA float
	,GrossTime  nvarchar(max)
	,Mins int
	,RowNum int
)
--get totals
insert into #d (ID, name, units, total, portPerc, PercentWOGNMA, GrossTime)
exec rpt101.investor.time_dist_by_investor 8,0,8,0,0

--fix goldman and first key
UPDATE #d
SET ID = CASE name
		WHEN 'MTGLQ Investors, LP' THEN 527 
		WHEN 'First Key' THEN 530
	ELSE ID end

--get rid of items we don't need
DELETE #d
WHERE 1=0
	OR ID = 999 --AND GrossTime = '0:01')
	OR GrossTime = '0:00'

--update minutes int column for adding later
UPDATE d
SET Mins = dateDiff(MINUTE,0,cast(GrossTime AS time))
FROM #d d

--add a rownum for updating later
UPDATE d
SET d.RowNum = a.RowNum
FROM #d d
INNER JOIN (SELECT d1.ID, RowNum = row_Number() OVER(ORDER by cast(GrossTime AS time) DESC) FROM #d d1) a ON a.ID = d.ID

--get total time needed added back (rounding)

DECLARE @totalTimeToAdd int 
SELECT 
	@totalTimeToAdd = (480 - sum(dateDiff(MINUTE,0,cast(grossTime AS datetime))))
FROM #d


--update mins to add minutes so that total day equals 8
UPDATE d
SET Mins = Mins + CASE WHEN @totalTimeToAdd >= RowNum THEN 1 ELSE 0 end
FROM #d d

select 
	ID 
	,H = Mins / 60
	,M = Mins % 60
from #d
order by 
	2 desc,3 desc, 1

