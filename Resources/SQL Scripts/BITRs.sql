DECLARE @empID int = 4151

SELECT 
	ID					= cast(coalesce(r.request_id,'') AS nvarchar)
	,Name				= lTrim(rTrim(coalesce(r.request_name,''))) 
	,Description		= lTrim(rTrim(util.strip_HTML(coalesce(replace(replace(replace(rc.comment_text,char(10),' '),char(13),' '),char(9),' '),''))))
	,[Create Date]		= coalesce(cast(cast(rc.create_date AS date) AS nvarchar),'')
	,[Current Status]	= lTrim(rTrim(coalesce(s.request_type_status_name,'')))
	,Owner				= coalesce(o.Employee_Name,'')
	,Creator			= coalesce(c.employee_name,'')
	,[Last Update]		= coalesce(cast(cast(rc1.create_date AS date) AS nvarchar),'')
	,[Last Update By]	= coalesce(x.employee_Name,'System')
from project.requests r with (nolock)
	left join project.request_comments rc  with (nolock) on r.request_id = rc.request_id and rc.request_comment_id = rc.main_request_comment_id and rc.delete_date is null
	left join project.request_status_h rh  with (nolock) on rc.request_comment_id = rh.request_comment_id and expiration_date is null
	left join project.request_type_statuses s  with (nolock) on s.request_type_status_id = rh.request_type_status_id
	left join company.vw_employees o  with (nolock) on rh.owner_id = o.employee_id
	left join company.vw_employees c  with (nolock) on r.request_by_id = c.employee_id
	left join company.vw_employees u  with (nolock) on rh.change_by_id = u.employee_ID
	left  join project.request_comments rc1  with (nolock) on rc1.request_ID = r.request_ID
	inner join (select request_ID, Max(request_comment_ID) MaxID from project.request_Comments  with (nolock) where 1=1 group by request_ID) maxRC on maxRC.maxID = rc1.request_Comment_ID
	left join company.vw_employees x  with (nolock) on x.employee_ID = rc1.create_by_id
where 1=1
	and s.request_type_status_name <> 'Released'
	and (1=0
		or rh.owner_id = coalesce(@empID,rh.owner_ID)	--me
		or exists (Select null from project.request_status_h h  with (nolock) WHERE h.change_by_id = coalesce(@empID,h.change_by_id) and h.request_ID = r.request_id) --status changed by me
		or exists (select null from project.request_Comments c  with (nolock) where c.create_by_id = coalesce(@empID,c.create_by_id) and c.request_ID = r.request_ID) --comment by me
		OR EXISTS (SELECT NULL FROM project.request_subscribers s  with (nolock) WHERE s.employee_ID = coalesce(@empID,s.employee_ID) AND s.request_ID = r.request_ID AND delete_date IS null) --subscribed by me
	)
order by 
	Case when rh.owner_id = coalesce(@empID,rh.owner_ID) then 0 else 1 end
	,[Current Status]
	,[Last Update] desc

-- Name 25
-- Description 30
-- Status 15
-- Owner 20
-- Creator 20
-- Last Update By 20