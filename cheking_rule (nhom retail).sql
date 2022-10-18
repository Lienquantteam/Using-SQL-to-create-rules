-- Main code for checking rule
-- Rule 1,2: default date <> 0 and CLSIND in (1,2,'')
-----------------------------------------------------------------------
DROP table #temp
SELECT * INTO #temp
FROM
(
	SELECT ACCTNO, DFDATE6,CLSIND FROM [VCB].[dbo].[acctow]
	WHERE DFDATE6 <> '0' and cast(CLSIND as float) in ('1','2','')
)a

SELECT distinct ACCTNO FROM #temp

SELECT * INTO #temp
FROM
(
	SELECT DFDATE7, ACCTNO,CLSIND FROM [Checking_Rule].[dbo].[acctow]
	WHERE DFDATE7 <> '0' and cast(CLSIND as float) in ('1','2','')

)a

SELECT distinct ACCTNO FROM #temp

==========================================================================
-- Rule 3: Thong ke nhung ma CURTYP khac AFCUR tai cung mot thoi diem khi map 2 bang ACCTOW va FACOW
DROP TABLE #temp
-------------------------------------------------------------------------
SELECT * INTO #temp
FROM
(
	SELECT a.DATE8, a.ACCTNO, a.PRDCOD, a.ORGAMT, b.AFAPLY, b.AFCUR, a.CURTYP 
	FROM 
	(
		SELECT DATE8, ACCTNO, PRDCOD, ORGAMT, AFAPNO, AFFCDE, AFSEQ, CURTYP 
		FROM [Checking_Rule].[dbo].[ACCTOW] 
		WHERE AFAPNO <> 0 and AFFCDE <> '0' and AFSEQ <> 0
	) a
	INNER JOIN (
		SELECT DATE8, AFAPLY,AFAPNO, AFFCDE, AFSEQ,AFCUR 
		FROM  [Checking_Rule].[dbo].[FACOW]
		WHERE AFAPNO <> 0 and AFFCDE <> '0' and AFSEQ <> 0
	) b
	ON a.AFAPNO = b.AFAPNO and a.AFFCDE = b.AFFCDE and a.AFSEQ = b.AFSEQ 
		and a.DATE8 = b.DATE8  
	WHERE a.CURTYP <> b.AFCUR
) c

SELECT * FROM #temp
SELECT COUNT(distinct ACCTNO) FROM #temp
==========================================================================
-- Rule 4: Ngay tat toan cac khoan vay tin dung (POFFD6) luon sau ngay giai
-- ngan (FRELD6). Co nghia la POFFD6 luon > FRELD6

-------------------------------------------------------------------------
UPDATE [Checking_Rule].[dbo].[ACCTOW_DATE8]
SET ORGDT8 = case 
			when POFFD6 like '195%' or ORGDT8 like '196%'
			then '20' + substring(convert(varchar,POFFD6),3,2) + right(convert(varchar,POFFD6),4)
			else POFFD6
			end,
	FRELD6 = case 
			when FRELD6 like '195%' or ORGDT8 like '196%'
			then '20' + substring(convert(varchar,FRELD6),3,2) + right(convert(varchar,FRELD6),4)
			else FRELD6
			end
-- Thong ke xem co bao nhieu gia tri POFFD6 in (0,'')
SELECT POFFD6, COUNT(*) as DEM FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
GROUP BY POFFD6
HAVING cast(POFFD6 as float) in ('0','')

--------------------------------------------------------------------------
SELECT * INTO #temp
FROM 
(
	SELECT ACCTNO, PRDCOD, FRELD6, POFFD6, FRELD8, POFFD8 
	FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
	WHERE cast(FRELD6 as float) <> 0 and cast(POFFD6 as float) <> 0
) b

-- Results:
SELECT * INTO #temp1
FROM
(
	SELECT *, 
		DATE_DIFF = DATEDIFF(Day,convert(varchar(8),FRELD8),convert(varchar(8),POFFD8))
	FROM #temp
	WHERE DATEDIFF(Day,convert(varchar(8),FRELD8),convert(varchar(8),POFFD8)) < 0
)a

SELECT COUNT(distinct ACCTNO) FROM #temp1

==========================================================================
-- Rule 5: Du no (CBAL) <> 0 thi phai co day du cac tin ve ngay giai ngan,
-- co nghia la FRELD6 <> 0. Vi vay, ta sex thong ke cac truong hop bi sai
-- khi CBAL <> 0 and FRELD6 = 0
DROP TABLE #temp
DROP TABLE #temp1
-------------------------------------------------------------------------
SELECT * INTO #temp
FROM
(
	SELECT ACCTNO, CBAL, FRELD6 FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
	WHERE CBAL <> '0' and FRELD6 = '0'
)a

SELECT COUNT(distinct ACCTNO) FROM #temp

==========================================================================
-- Rule 6: Thong ke nhung TH co ngay payoff va co du no nhung  status = 2 (close)
DROP TABLE #temp
-------------------------------------------------------------------------
SELECT distinct(STATUS) FROM [dbo].[ACCTOW]

SELECT ACCTNO, POFFD6, CBAL, STATUS INTO #temp
FROM [dbo].[ACCTOW]
WHERE POFFD6 <> 0 and STATUS = 2 and CBAL <> 0

SELECT COUNT(distinct ACCTNO) FROM #temp

==========================================================================
--Rule 7:  PRDCOD la ma duy nhat de xac dinh san pham va PRDCOD luon <> 0
DROP TABLE #temp
-------------------------------------------------------------------------
SELECT ACCTNO, PRDCOD INTO #temp
FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
WHERE PRDCOD < '0'

SELECT COUNT(distinct ACCTNO) FROM #temp

==========================================================================
-- Rule 8: Du no (CBAL) phai < Han muc cua khach hang (ORGAMT) o cung bang ACCTOW
DROP TABLE #temp
-- Thong ke truong hop CBAL = 0
SELECT CBAL FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
WHERE CBAL = '0'
-- ORGAMT < 0
SELECT ORGAMT FROM [dbo].[ACCTOW]
WHERE ORGAMT < '0'

-------------------------------------------------------------------------
SELECT ACCTNO, PRDCOD, AFFCDE, CBAL, ORGAMT INTO #temp 
FROM [dbo].[ACCTOW]
WHERE CBAL > ORGAMT and CBAL >= 0 and ORGAMT >= 0 

SELECT distinct ACCTNO FROM #temp

==========================================================================
-- Rule 9: Ngay giai ngan (FRELD6) >= Ngay mo tai khoan dau tien (ORGDT6)
DROP TABLE #temp
-------------------------------------------------------------------------
UPDATE [Checking_Rule].[dbo].[ACCTOW_DATE8]
SET ORGDT8 = case 
			when ORGDT8 like '195%' or ORGDT8 like '196%'
			then '20' + substring(convert(varchar,ORGDT8),3,2) + right(convert(varchar,ORGDT8),4)
			else ORGDT8
			end	
-- Thong ke xem co bao nhieu gia tri FRELD6 in (0,'')
SELECT FRELD6, COUNT(*) as DEM FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
GROUP BY FRELD6
HAVING cast(FRELD6 as float) in ('0','')
-- ORGDT6 in (0,'')
SELECT ORGDT6, COUNT(*) as DEM FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
GROUP BY ORGDT6
HAVING cast(ORGDT6 as float) in ('0','')

---------------------------------------------------------------------------
SELECT * INTO #temp
FROM 
(
	SELECT ACCTNO, AFFCDE, PRDCOD,FRELD6, FRELD8, ORGDT6, ORGDT8 
	FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
	WHERE cast(FRELD6 as float) not in ('0','') and cast(ORGDT6 as float) not in ('0','')
) b
-- Find wrong values in #temp table:
SELECT * INTO #temp1
FROM
(
	SELECT *, 
		DATE_DIFF = DATEDIFF(Day,convert(varchar(8),ORGDT8),convert(varchar(8),FRELD8))
	FROM #temp
	WHERE DATEDIFF(Day,convert(varchar(8),ORGDT8),convert(varchar(8),FRELD8)) < 0
)a

SELECT COUNT(distinct ACCTNO) FROM #temp1

==========================================================================
-- Rule 10: Ky han khoan vay (TERM) = Ngay dao han cua TK (MATDT8) - Ngay giai ngan dau tien (FRELD8)
DROP TABLE #temp
DROP TABLE #temp1
-------------------------------------------------------------------------
UPDATE [Checking_Rule].[dbo].[ACCTOW_DATE8]
SET MATDT8 = case 
			when MATDT8 like '195%' or MATDT8 like '196%'
			then '20' + substring(convert(varchar,MATDT8),3,2) + right(convert(varchar,MATDT8),4)
			else MATDT8
			end	
-- Thong ke xem co bao nhieu TERM bi loi < 0
SELECT TERM FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
WHERE cast(TERM as float) < '0'
-- Thong ke xem MATDT6 = 0 hoac blank
SELECT COUNT(MATDT6) FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
WHERE cast(MATDT6 as float) in ('0','')

-------------------------------------------------------------------------
SELECT ACCTNO,PRDCOD, TMCODE, TERM, FRELD6, FRELD8, MATDT8, MATDT6 
INTO #temp
FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
WHERE cast(TMCODE as varchar(20)) <> '0' and cast(TERM as float) <> '0' and
cast(MATDT6 as float) not in ('0','') and cast(FRELD6 as float) not in ('0','')
GO
ALTER TABLE #temp
ADD TERM_date float NULL,i
	DATE_DIFF float NULL,
	Check_diff float NULL
GO
UPDATE #temp
SET TERM_date = case
				when cast(TMCODE as varchar(10)) = 'M' then TERM * 30
				else TERM
				end,
	DATE_DIFF = DATEDIFF(Day,convert(varchar(8),FRELD8),convert(varchar(8),MATDT8)),
	Check_diff = case
				when DATE_DIFF > TERM_date + 2 or DATE_DIFF < TERM_date -2 and cast(TMCODE as varchar(10)) = 'D' then 1
				when DATE_DIFF < TERM_date - 5 and cast(TMCODE as varchar(10)) = 'M' then 1
				when DATE_DIFF >= TERM_date + 10 and TERM <= 12 and cast(TMCODE as varchar(10)) = 'M' then 1
				when DATE_DIFF >= TERM_date + 42 and TERM <= 60 and TERM > 12 and cast(TMCODE as varchar(10)) = 'M' then 1
				when DATE_DIFF >= TERM_date + 82  and TERM <= 120 and TERM > 60 and cast(TMCODE as varchar(10)) = 'M' then 1
				when DATE_DIFF >= TERM_date + 202 and TERM <= 300 and TERM > 120 and cast(TMCODE as varchar(10)) = 'M' then 1
				when DATE_DIFF >= TERM_date + 482 and TERM <= 720 and TERM > 300 and cast(TMCODE as varchar(10)) = 'M' then 1
				else 0
				end
-- Results:
SELECT * FROM #temp
WHERE Check_diff = 1

SELECT COUNT(distinct ACCTNO) FROM #temp
WHERE Check_diff = 1 

==========================================================================
-- Rule 11: Ngay goc den han tiep theo (NPDT6) phai < Ky han khoan vay tren hop dong (MATDT6)
DROP TABLE #temp
DROP TABLE #temp1
-------------------------------------------------------------------------
UPDATE [Checking_Rule].[dbo].[ACCTOW_DATE8]
SET NPDT8 = case 
			when NPDT8 like '195%' or NPDT8 like '196%'
			then '20' + substring(convert(varchar,NPDT8),3,2) + right(convert(varchar,NPDT8),4)
			else NPDT8
			end,
	NIPDT8 = case 
			when NIPDT8 like '195%' or NIPDT8 like '196%'
			then '20' + substring(convert(varchar,NIPDT8),3,2) + right(convert(varchar,NIPDT8),4)
			else NIPDT8
			end
-- Thong ke xem co bao nhieu NPDT6 bi loi < 0
SELECT NPDT6 FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
WHERE cast(NPDT6 as float) < '0'
-- NIPDT6 < 0
SELECT NIPDT6 FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
WHERE cast(NIPDT6 as float) < '0'

-------------------------------------------------------------------------
SELECT ACCTNO, NPDT6, NPDT8, MATDT8, MATDT6
INTO #temp
FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
WHERE cast(MATDT6 as float) not in ('0','') and cast(NPDT6 as float) not in ('0','')
GO
SELECT *, 
	DATEDIFF(Day,convert(varchar(8),NPDT8),convert(varchar(8),MATDT8)) AS DATE_DIFF

INTO #temp1
FROM #temp
WHERE DATEDIFF(Day,convert(varchar(8),NPDT8),convert(varchar(8),MATDT8)) < '0'

-- Results:
SELECT * FROM #temp1
SELECT COUNT(distinct ACCTNO) FROM #temp1

==========================================================================
-- Rule 12: Ngay goc den lai tiep theo, tinh theo lai suat (NIPDT6) cung phai < Ky han khoan vay tren hop dong (MATDT6)
DROP TABLE #temp
DROP TABLE #temp1
-------------------------------------------------------------------------
SELECT ACCTNO, NIPDT6, NIPDT8, MATDT8, MATDT6
INTO #temp
FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
WHERE cast(MATDT6 as float) not in ('0','') and cast(NIPDT6 as float) not in ('0','')
GO
SELECT *, 
	DATEDIFF(Day,convert(varchar(8),NIPDT8),convert(varchar(8),MATDT8)) AS DATE_DIFF
INTO #temp1
FROM #temp
WHERE DATEDIFF(Day,convert(varchar(8),NIPDT8),convert(varchar(8),MATDT8)) < '0'

-- Results:
SELECT * FROM #temp1
SELECT COUNT(distinct ACCTNO) FROM #temp1

==========================================================================
-- Rule 13: Chi so tieu chuan neu lai suat tha noi duoc ap dung (PRATEN)
va JRCRATE, RATE phai luon la mot so thuc duong
DROP TABLE #temp
DROP TABLE #temp1
-------------------------------------------------------------------------
-- PRATEN 
SELECT ACCTNO, PRATEN INTO #temp
FROM [Checking_Rule].[dbo].[ACCTOW]
WHERE PRATEN <'0'
SELECT COUNT(distinct ACCTNO) FROM #temp

-- JRCRATE
DROP TABLE #temp
SELECT ACCTNO, JRCRATE INTO #temp
FROM [Checking_Rule].[dbo].[ACCTOW]
WHERE JRCRATE <'0'
SELECT COUNT(distinct ACCTNO) FROM #temp

-- Rate
DROP TABLE #temp
SELECT ACCTNO, RATE INTO #temp
FROM [Checking_Rule].[dbo].[ACCTOW]
WHERE RATE <'0'
SELECT COUNT(distinct ACCTNO) FROM #temp

==========================================================================
-- RULE 13: Han muc tin dung (ORGMAT) >= du no (CBAL) & <= gia tri hop dong (AFAPLY)
DROP TABLE #temp
-------------------------------------------------------------------------
-- ORGMAT > CBAL
SELECT ACCTNO, CURTYP, CBAL, ORGAMT 
INTO #temp
FROM [Checking_Rule].[dbo].[ACCTOW]
WHERE CBAL > ORGAMT

SELECT * FROM #temp
SELECT COUNT(distinct ACCTNO) FROM #temp

-- ORGMAT(ACCTNOW) > CBAL(FACOW). Chu y: Khi so sanh 2 truong tu 2 bang nay ta phai
-- so sanh chung tai cung mot thoi diem (DATE8) va cung mot ma tien te (CURTYP)
DROP TABLE #temp
SELECT * INTO #temp
FROM
(
	SELECT a.DATE8, a.ACCTNO, a.PRDCOD, a.ORGAMT, b.AFAPLY, b.AFCUR, a.CURTYP 
	FROM 
	(
		SELECT DATE8, ACCTNO, PRDCOD, ORGAMT, AFAPNO, AFFCDE, AFSEQ, CURTYP 
		FROM [Checking_Rule].[dbo].[ACCTOW] 
		WHERE AFAPNO <> 0 and AFFCDE <> '0' and AFSEQ <> 0
	) a
	INNER JOIN (
		SELECT DATE8, AFAPLY,AFAPNO, AFFCDE, AFSEQ,AFCUR 
		FROM  [Checking_Rule].[dbo].[FACOW]
		WHERE AFAPNO <> 0 and AFFCDE <> '0' and AFSEQ <> 0
	) b
	ON a.AFAPNO = b.AFAPNO and a.AFFCDE = b.AFFCDE and a.AFSEQ = b.AFSEQ 
		and a.DATE8 = b.DATE8 and a.CURTYP = b.AFCUR
	WHERE a.ORGAMT > b. AFAPLY 
) c

SELECT * FROM #temp
SELECT COUNT(DISTINCT ACCTNO) FROM #temp

==========================================================================
-- Rule 14: Du no cua cac khoan tin dung chuyen sang ngoai bang (WOBAL)
DROP TABLE #temp
-------------------------------------------------------------------------
SELECT * INTO #temp
FROM
(
	SELECT ACCTNO, WODATE6,TYPE FROM [dbo].[ACCTOW]
	WHERE  WOBAL = 0  and WODATE6 <> 0
 ) a

SELECt distinct ACCTNO FROM #temp

SELECT ACCTNO, WODATE6,TYPE FROM [dbo].[ACCTOW]
WHERE  WOBAL <> 0  and WODATE6 = 0

==========================================================================
-- Rule 15: Do han muc cho vay (DRLIMT) co the thay doi theo thoi gian
-- do vay, khi xet tai cung mot thoi diem thi  DRLIMT<= gia tri hop dong (AFAPLY) 
-- va >= du no tin dung (CBAL)
DROP TABLE #temp
-------------------------------------------------------------------------
SELECT * INTO #temp
FROM (
		SELECT a.DATE8, b.AFCUR, a.CURTYP,a.CIFNO, a.ACCTNO, a.AFAPNO,a.AFFCDE, a.AFSEQ, a.DRLIMT,b.AFAPLY 
		FROM (
		SELECT DATE8, ACCTNO,CIFNO,DRLIMT,AFAPNO, AFFCDE, AFSEQ, CURTYP 
		FROM [Checking_Rule].[dbo].[ACCTOW] 
		WHERE AFAPNO <> '0' and AFFCDE <> '0' and AFSEQ <> '0'
		) a
		INNER JOIN (
		SELECT DATE8, AFAPLY,AFAPNO, AFFCDE, AFSEQ,AFCUR 
		FROM [Checking_Rule].[dbo].[FACOW]
		WHERE AFAPNO <> '0' and AFFCDE <> '0' and AFSEQ <> '0'
		)b
	ON a.AFAPNO = b.AFAPNO and a.AFFCDE = b.AFFCDE and a.AFSEQ = b.AFSEQ
		 and a.CURTYP = b.AFCUR and a.DATE8 = b.DATE8
	WHERE a.DRLIMT > b. AFAPLY
) c

SELECT * FROM #temp
SELECT COUNT(distinct ACCTNO) FROM #temp

-- DRLIMT >= CBAL is TRUE
SELECT DATE8, ACCTNO, CURTYP, CBAL, DRLIMT 
INTO #temp
FROM [Checking_Rule].[dbo].[ACCTOW]
WHERE DRLIMT < CBAL

SELECT * FROM #temp
SELECT COUNT(distinct ACCTNO) FROM #temp

==========================================================================
-- Rule 16: Ngay dao han cua khoan tin dung (MATDT6) phai <> 0
DROP TABLE #temp
-------------------------------------------------------------------------
SELECT DATE8, ACCTNO, MATDT6, AFFCDE 
INTO #temp
FROM [Checking_Rule].[dbo].[ACCTOW]
WHERE convert(varchar,MATDT6) in ('0', '')

SELECT * FROM #temp
SELECT COUNT(distinct ACCTNO) FROM #temp

==========================================================================
-- Rule 17: Ngay dao han tai san dam bao (CCBND6)  luon sau ngay het han tai khoan (MATDT6)
-- co nghia la CCBND6 luon > MATDT6
DROP TABLE #temp
-------------------------------------------------------------------------
UPDATE [Checking_Rule].[dbo].[COLLOW_DATE8]
SET CCBND6 = case 
			when CCBND6 like '195%' or CCBND6 like '196%'
			then '20' + substring(convert(varchar,CCBND6),3,2) + right(convert(varchar,CCBND6),4)
			else CCBND6
			end
-- Thong ke gia tri bang 0 va < 0 
 SELECT Count(CCBND6) FROM [Checking_Rule].[dbo].[COLLOW]
 WHERE CCBND6 = 0
 SELECT Count(CCBND6) FROM [Checking_Rule].[dbo].[COLLOW]
 WHERE CCBND6 < 0

-- Map 2 bang ACCTOW va COLLOW 
SELECT *,
	DATE_DIFF = DATEDIFF(DAY, convert(varchar,MATDT8), convert(varchar,CCBND8)) 
INTO #temp
FROM (
	SELECT a.DATE8, b.CCDCID, a.ACCTNO, a.MATDT6, a.MATDT8, b.CCBND8, b.CCBND6 
	FROM (
		SELECT DATE8, ACCTNO, MATDT6,MATDT8, AFAPNO, AFFCDE, AFSEQ 
		FROM [Checking_Rule].[dbo].[ACCTOW_DATE8] 
		WHERE AFAPNO <> '0' and AFFCDE <> '0' and AFSEQ <> '0' and MATDT6 <> '0'
	) a
	INNER JOIN (
		SELECT DATE8, CCBND6, CCBND8, AANO, FCODE, FSEQ, CCDCID
		FROM [Checking_Rule].[dbo].[COLLOW_DATE8] 
		WHERE AANO <> '0' and  FCODE <> '0' and FSEQ <> '0' and CCBND6 <> '0'
	)b
	ON a.AFAPNO = b.AANO and a.AFFCDE = b.FCODE and 
		a.AFSEQ = b.FSEQ and a.DATE8 = b.DATE8
) c

-- Results:
SELECT * INTO #temp1 
FROM #temp
WHERE DATE_DIFF < '0'

SELECT * FROM #temp1
SELECT COUNT(distinct ACCTNO) FROM #temp1

==========================================================================
-- Rule 18: Han muc duoc ghi nhan trong hop dong vay von phai < han muc 
-- da duoc phe duyet cho khach hang dua tren co so phan tich rui ro.
DROP TABLE #temp
DROP TABLE #temp1
-------------------------------------------------------------------------
SELECT a.DATE8, a.ACCTNO, a.CURTYP,b.AFCUR,a.AFFCDE, b.AFAPLY, a.CBAL, a.AMTREL, b.AFFAMT 
INTO #temp
FROM (
	SELECT DATE8, ACCTNO, CURTYP, AMTREL, CBAL, AFAPNO, AFFCDE, AFSEQ 
	FROM [Checking_Rule].[dbo].[ACCTOW_DATE8] 
	WHERE AFAPNO <> '0' and AFFCDE <> '0' and AFSEQ <> '0'
) a
INNER JOIN (
	SELECT DATE8, AFCUR, AFAPLY,AFAPNO, AFFCDE, AFSEQ, AFFAMT 
	FROM [Checking_Rule].[dbo].[FACOW_DATE8]
	WHERE AFAPNO <> '0' and AFFCDE <> '0' and AFSEQ <> '0'
) b
ON a.AFAPNO = b.AFAPNO and a.AFFCDE = b.AFFCDE and 
	a.AFSEQ = b.AFSEQ and a.DATE8 = b.DATE8 and a.CURTYP = b.AFCUR
GO
ALTER TABLE #temp
--drop column Signal
ADD Signal float NULL
GO
UPDATE #temp
SET Signal = case
			when AFFCDE = '003' and AFAPLY >= CBAL then 0
			when AFFCDE in ('001','002') and AFAPLY >= AMTREL then 0
			--when AFAPLY >= AFFAMT then 0
			else 1
			end
-- Final results: Filter Signal = 1 
SELECT * INTO #temp1 
FROM #temp
WHERE Signal = 1

SELECT * FROM #temp1 
SELECT COUNT(distinct ACCTNO) FROM #temp1

==========================================================================
-- Rule 19: giong rule 18 chi khac la dieu kien chat hon 
DROP TABLE #temp
DROP TABLE #temp1
-------------------------------------------------------------------------
SELECT a.DATE8, a.ACCTNO, a.CURTYP,b.AFCUR,a.AFFCDE, b.AFAPLY, a.CBAL, a.AMTREL, b.AFFAMT 
INTO #temp
FROM (
	SELECT DATE8, ACCTNO, CURTYP, AMTREL, CBAL, AFAPNO, AFFCDE, AFSEQ 
	FROM [Checking_Rule].[dbo].[ACCTOW_DATE8] 
	WHERE AFAPNO <> '0' and AFFCDE <> '0' and AFSEQ <> '0'
) a
INNER JOIN (
	SELECT DATE8, AFCUR, AFAPLY,AFAPNO, AFFCDE, AFSEQ, AFFAMT 
	FROM [Checking_Rule].[dbo].[FACOW_DATE8]
	WHERE AFAPNO <> '0' and AFFCDE <> '0' and AFSEQ <> '0'
) b
ON a.AFAPNO = b.AFAPNO and a.AFFCDE = b.AFFCDE and 
	a.AFSEQ = b.AFSEQ and a.DATE8 = b.DATE8 and a.CURTYP = b.AFCUR
GO
ALTER TABLE #temp
-- drop column Signal
ADD Signal float NULL
GO
UPDATE #temp
SET Signal = case
			when AFFCDE = '003' and AFAPLY >= CBAL then 0
			when AFFCDE in ('001','002') and AFAPLY >= AMTREL then 0
			else 1
			end
-- Final results: Filter Signal = 1 
SELECT * INTO #temp1 
FROM #temp
WHERE Signal = 1

SELECT * FROM #temp1 
SELECT COUNT(distinct ACCTNO) FROM #temp1

==========================================================================
-- Rule 20: Ngày phê duyệt/ky hop dong tin dung (AFARD6) phai sau ngày apply (AFAPD6)
-- truoc ngay mo tai khoan (ORGDT6)
DROP TABLE #temp
DROP TABLE #temp1
-------------------------------------------------------------------------
UPDATE [Checking_Rule].[dbo].[FACOW_DATE8]
SET AFARD8 = case 
			when AFARD8 like '195%' or AFARD8 like '196%'
			then '20' + substring(convert(varchar,AFARD8),3,2) + right(convert(varchar,AFARD8),4)
			else AFARD8
			end,
	AFAPD8 = case 
			when AFAPD8 like '195%' or AFAPD8 like '196%'
			then '20' + substring(convert(varchar,AFAPD8),3,2) + right(convert(varchar,AFAPD8),4)
			else AFAPD8
			end
-------------------------------------------------------------------------
SELECT *,
	DATE_DIFF = DATEDIFF(DAY, convert(varchar,AFAPD8), convert(varchar,AFARD8)) 
INTO #temp
FROM
(
	SELECT DATE8, AFAPNO, AFFCDE, AFSEQ, AFAPD6, AFAPD8, AFARD8, AFARD6 
	FROM [Checking_Rule].[dbo].[FACOW_DATE8]
	WHERE AFARD6 <> '0' and AFAPD6 <> '0' and AFAPNO <> '0' and AFFCDE <> '0'
		and AFSEQ <> '0' and AFARD8 <> '0' and AFAPD8 <> '0'
)a

SELECT * INTO #temp1
FROM #temp
WHERE convert(int, DATE_DIFF) < 0

-- Results:
SELECT * FROM #temp1
SELECT distinct AFAPNO, AFFCDE, AFSEQ FROM #temp1

------------------------- AFARD6 < ORGDT6-----------------------------------
DROP TABLE #temp
DROP TABLE #temp1
UPDATE [Checking_Rule].[dbo].[ACCTOW_DATE8]
SET ORGDT8 = case 
			when ORGDT8 like '195%' or ORGDT8 like '196%'
			then '20' + substring(convert(varchar,ORGDT8),3,2) + right(convert(varchar,ORGDT8),4)
			else ORGDT8
			end
-------------------------------------------------------------------------
SELECT a.DATE8, a.ACCTNO, a.ORGDT6, a.ORGDT8, b.AFARD8, b.AFARD6,
		DATE_DIFF = DATEDIFF(DAY, convert(varchar,AFARD8), convert(varchar,ORGDT8)) 
INTO #temp
FROM (
	SELECT DATE8, ACCTNO, AFAPNO, AFFCDE, AFSEQ, ORGDT6, ORGDT8 
	FROM [Checking_Rule].[dbo].[ACCTOW_DATE8] 
	WHERE AFAPNO <> '0' and AFFCDE <> '0' and AFSEQ <> '0' and ORGDT6 <> '0'
) a
INNER JOIN (
	SELECT DATE8, AFAPLY,AFAPNO, AFFCDE, AFSEQ, AFARD6, AFARD8
	FROM [Checking_Rule].[dbo].[FACOW_DATE8]
	WHERE AFAPNO <> '0' and AFFCDE <> '0' and AFSEQ <> '0' and AFARD6 <> '0'
) b
ON a.AFAPNO = b.AFAPNO and a.AFFCDE = b.AFFCDE and 
	a.AFSEQ = b.AFSEQ and a.DATE8 = b.DATE8

-- Reusults:
SELECT * INTO #temp1
FROM #temp
WHERE DATE_DIFF < '0'

SELECT * FROM #temp1
SELECT COUNT(distinct ACCTNO) FROM #temp1

==========================================================================
-- Rule 21: Ky han khoan vay tren hop dong (AFTERM) = AFEXP7 - AFARD7
DROP TABLE #temp
DROP TABLE #temp1
-------------------------------------------------------------------------
SELECT AFAPNO, AFFCDE, AFSEQ, AFTCOD, AFTERM, AFEXP7, AFARD7,
		DATE_DIFF = case
					when cast(left(AFEXP7,4) as float) >= cast(left(AFARD7,4) as float) then 
					365 * (cast(left(AFEXP7,4) as float) - cast(left(AFARD7,4) as float)) + 
					(cast(right(AFEXP7,3) as float) - cast(right(AFARD7,3) as float))
					else -(365 * (cast(left(AFEXP7,4) as float) - cast(left(AFARD7,4) as float)) +
					(cast(right(AFEXP7,3) as float) - cast(right(AFARD7,3) as float)))
					end
INTO #temp
FROM [Checking_Rule].[dbo].[FACOW]	
WHERE  AFAPNO <> '0' and AFFCDE <> '0' and AFSEQ <> '0'
GO
ALTER TABLE #temp
ADD AFTERM_new float NULL
GO 
UPDATE #temp
SET AFTERM_new = case 
				when AFTCOD = 'M' then AFTERM * 30
				else AFTERM
				end
GO
ALTER TABLE #temp
--DROP column check_diff
ADD check_diff float NULL
GO
UPDATE #temp
SET check_diff = case
				when DATE_DIFF <> AFTERM_new and cast(AFTCOD as varchar(10)) = 'D' then 1
				when DATE_DIFF < AFTERM_new - 5 and cast(AFTCOD as varchar(10)) = 'M' then 1
				when DATE_DIFF >= AFTERM_new + 10 and AFTERM <= 12 and cast(AFTCOD as varchar(10)) = 'M' then 1
				when DATE_DIFF >= AFTERM_new + 42 and AFTERM <= 60 and AFTERM > 12 and cast(AFTCOD as varchar(10)) = 'M' then 1
				when DATE_DIFF >= AFTERM_new + 82  and AFTERM <= 120 and AFTERM > 60 and cast(AFTCOD as varchar(10)) = 'M' then 1
				when DATE_DIFF >= AFTERM_new + 202 and AFTERM <= 300 and AFTERM > 120 and cast(AFTCOD as varchar(10)) = 'M' then 1
				when DATE_DIFF >= AFTERM_new + 482 and AFTERM <= 720 and AFTERM > 300 and cast(AFTCOD as varchar(10)) = 'M' then 1
				else 0
				end

SELECT * INTO #temp1
FROM #temp
WHERE check_diff = 1
 SELECT * FROM #temp
 where check_diff = '0'
-- Results:
SELECT * FROM #temp1
SELECT distinct AFAPNO, AFFCDE, AFSEQ FROM #temp1

==========================================================================
-- Rule 22: Ky han tren khoan vay (AFTCOD) chi nhan 2 gia tri D/M. Neu khac 2 gia tri nay thi la sai
DROP TABLE #temp
DROP TABLE #temp1
-------------------------------------------------------------------------
SELECT AFAPNO, AFFCDE, AFSEQ, AFTCOD
INTO #temp
FROM [Checking_Rule].[dbo].[FACOW]
WHERE AFTCOD not in ('D','M') and AFAPNO <> '0' and AFFCDE <> '0' and AFSEQ <> '0'

SELECT * FROM #temp
SELECT distinct AFAPNO, AFFCDE, AFSEQ FROM #temp

==========================================================================
-- Rule 23: Tong giai ngan phai luon (AVLBAL) < Han muc trong hop dong (AFAPLY)
DROP TABLE #temp
DROP TABLE #temp1
-------------------------------------------------------------------------
-- Thong ke
SELECT AVLBAL, AFAPLY FROM [dbo].[FACOW]
WHERE AVLBAL < 0
SELECT AVLBAL, AFAPLY FROM [dbo].[FACOW]
WHERE AFAPLY < 0
-- Main code
SELECT AFAPNO, AFFCDE, AFSEQ, AVLBAL, AFAPLY 
INTO #temp
FROM [Checking_Rule].[dbo].[FACOW]
WHERE AVLBAL > AFAPLY and AFAPLY >= 0 and AFAPNO <> '0' 
		and AFFCDE <> '0' and AFSEQ <> '0'

SELECT * FROM #temp
SELECT distinct AFAPNO, AFFCDE, AFSEQ FROM #temp

==========================================================================
-- Rule 24: Ngay goc den han (NPDT6) < ngay dao han (MATDT6) 
-- Ngay lai den han (NIPDT6) < ngay dao han (MATDT6)
-- Chu y: Phai tren la kiem tra trong bang ACCTOW bay gio la trong bang TRANSOW
-- Cach kiem tra thi hoan toan giong nhau
DROP TABLE #temp
DROP TABLE #temp1
-------------------------------------------------------------------------
UPDATE [Checking_Rule].[dbo].[TRANSOW_DATE8]
SET NPDT8 = case 
			when NPDT8 like '195%' or NPDT8 like '196%'
			then '20' + substring(convert(varchar,NPDT8),3,2) + right(convert(varchar,NPDT8),4)
			else NPDT8
			end,
	NIPDT8 = case 
			when NIPDT8 like '195%' or NIPDT8 like '196%'
			then '20' + substring(convert(varchar,NIPDT8),3,2) + right(convert(varchar,NIPDT8),4)
			else NIPDT8
			end
-- Thong ke xem co bao nhieu NPDT6 bi loi < 0
SELECT NPDT6 FROM [Checking_Rule].[dbo].[TRANSOW_DATE8]
WHERE cast(NPDT6 as float) < '0'
-- NIPDT6 < 0
SELECT NIPDT6 FROM [Checking_Rule].[dbo].[TRANSOW_DATE8]
WHERE cast(NIPDT6 as float) < '0'

-------------------------------------------------------------------------
SELECT a.DATE8, a.ACCTNO, b.NPDT6, b.NPDT8, a.MATDT8, a.MATDT6,
		DATE_DIFF = DATEDIFF(DAY, convert(varchar,NPDT8), convert(varchar,MATDT8)) 
INTO #temp
FROM (
	SELECT DATE8, ACCTNO, MATDT8, MATDT6
	FROM [Checking_Rule].[dbo].[ACCTOW_DATE8] 
	WHERE ACCTNO <> '0' and MATDT8 <> '0' and MATDT6 <> '0' 
) a
INNER JOIN (
	SELECT DATE8, ACCTNO, NPDT6, NPDT8
	FROM [Checking_Rule].[dbo].[TRANSOW_DATE8]
	WHERE ACCTNO <> '0' and NPDT6 <> '0' and NPDT8 <> '0' 
) b
ON a.ACCTNO = b.ACCTNO and a.DATE8 = b.DATE8 
GO
SELECT * INTO #temp1
FROM #temp
WHERE DATE_DIFF < '0'

-- Results:
SELECT * FROM #temp1
SELECT COUNT(distinct ACCTNO) FROM #temp1

-------------------------------------------------------------------------
-- Ngay lai den han (NIPDT6) < ngay dao han (MATDT6)
DROP TABLE #temp
DROP TABLE #temp1

SELECT a.DATE8, a.ACCTNO, b.NIPDT6, b.NIPDT8, a.MATDT8, a.MATDT6,
		DATE_DIFF = DATEDIFF(DAY, convert(varchar,NIPDT8), convert(varchar,MATDT8)) 
INTO #temp
FROM (
	SELECT DATE8, ACCTNO, MATDT8, MATDT6
	FROM [Checking_Rule].[dbo].[ACCTOW_DATE8] 
	WHERE ACCTNO <> '0' and MATDT8 <> '0' and MATDT6 <> '0' 
) a
INNER JOIN (
	SELECT DATE8, ACCTNO, NIPDT6, NIPDT8
	FROM [Checking_Rule].[dbo].[TRANSOW_DATE8]
	WHERE ACCTNO <> '0' and NIPDT6 <> '0' and NIPDT8 <> '0' 
) b
ON a.ACCTNO = b.ACCTNO and a.DATE8 = b.DATE8 

SELECT * INTO #temp1
FROM #temp
WHERE DATE_DIFF < '0'

-- Results:
SELECT * FROM #temp1
SELECT COUNT(distinct ACCTNO) FROM #temp1

==========================================================================
-- Rule 25: nhom no tai khoan (CLSIND) >= 2 thi DATEC >= 10
DROP TABLE #temp
DROP TABLE #temp1
-------------------------------------------------------------------------

SELECT a.ACCTNO, a.DATE8, a.CLSIND, b.DATEC 
INTO #temp
FROM [dbo].[ACCTOW] a
INNER JOIN [dbo].[TRANSOW] b
ON a.DATE8 = b.DATE8 and a.ACCTNO = b.ACCTNO
WHERE a.CLSIND < 2 and b.DATEC > 10 

SELECT a.ACCTNO, a.DATE8, a.CLSIND, b.DATEC 
INTO #temp1
FROM [dbo].[ACCTOW] a
INNER JOIN [dbo].[TRANSOW] b
ON a.DATE8 = b.DATE8 and a.ACCTNO = b.ACCTNO
WHERE a.CLSIND >=2 and b.DATEC >= 10 


SELECT a.ACCTNO, a.DATE8, a.CLSIND, d.NHOM6, d.NHOM7,d.DATEC
FROM [dbo].[ACCTOW] a
INNER JOIN 
	(SELECT b.ACCTNO, b.DATE8, c.NHOM6, c.NHOM7,b.DATEC FROM [dbo].[TRANSOW] b
	INNER JOIN [dbo].[NHOMNO] c
	ON b.ACCTNO = c.ACCTNO and b.DATE8 = c.DATE8) d
ON a.DATE8 = d.DATE8 and a.ACCTNO = d.ACCTNO
WHERE d.NHOM6 < 3 and d.DATEC > 90 

SELECT * FROM #temp
SELECT * FROM #temp1
SELECT COUNT(distinct ACCTNO) FROM #temp
select distinct PRDCOD from [dbo].[ACCTOW]
==========================================================================
-- Rule 26: Xem phan bo tai FCODE bang COLLOW
SELECT * INTO #temp
FROM 
(
	SELECT FCODE, count(distinct CCDCID) AS ALLOCATION 
	FROM [Checking_Rule].[dbo].[COLLOW_DATE8]
	GROUP BY FCODE
)a

DROP TABLE #temp
SELECT * INTO #temp
FROM 
(
	SELECT PRDCOD, count(distinct ACCTNO) AS ALLOCATION 
	FROM [Checking_Rule].[dbo].[ACCTOW_DATE8]
	GROUP BY PRDCOD
)a

SELECT * FROM #temp

select distinct AFTCOD from FACOW_DATE8
==========================================================================

-- Shrink file *.log
USE tempdb;
GO 
-- Truncate the log by changing the database recovery model to SIMPLE.
ALTER DATABASE Checking_Rule;
SET RECOVERY SIMPLE;
GO	
-- Shrink the truncated log file to 1 Mb.
DBCC SHRINKFILE (templog, 1);
GO

