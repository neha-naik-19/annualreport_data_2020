-- phpMyAdmin SQL Dump
-- version 5.0.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Feb 22, 2021 at 10:51 AM
-- Server version: 10.4.11-MariaDB
-- PHP Version: 7.4.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `annualreport`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAuthor` (IN `fname` TEXT, IN `mname` TEXT, IN `lname` TEXT, IN `subtype` INT, IN `fromdate` DATE, IN `todate` DATE, IN `category` VARCHAR(25), IN `nationality` INT, IN `categoryname` VARCHAR(20), IN `authortypeid` INT, IN `title` TEXT, IN `conference` TEXT, IN `ranking` TEXT)  BEGIN
 
 	DECLARE element varchar(150);
    
    DECLARE query1 text;
    DECLARE query2 text;
    DECLARE concatquery text;
    DECLARE catcheck text;
    DECLARE checktext text;
    DECLARE rankingcopy int;
    
	IF CONVERT(ranking,int) = 0 THEN 
		SET rankingcopy = 0; 
	ELSE 
		SET rankingcopy = 1; 
	END IF;
    
    IF fname = '' THEN SET fname = ','; END IF;
    IF mname = '' THEN SET mname = ','; END IF;
    IF lname = '' THEN SET lname = ','; END IF;
    
    SET query1 = ''; SET query2 = ''; SET concatquery = '';
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Rankings_Print_Author;
    DROP TEMPORARY TABLE IF EXISTS Temp_Ranking_Print_Author_Table;
    DROP TEMPORARY TABLE IF EXISTS Temp_Author_Fname;
    DROP TEMPORARY TABLE IF EXISTS Temp_Author_Mname;
    DROP TEMPORARY TABLE IF EXISTS Temp_Author_Lname;
    DROP TEMPORARY TABLE IF EXISTS Temp_Header_Id;
    
    CREATE TEMPORARY TABLE Temp_Rankings_Print_Author (rankingids int);
    CREATE TEMPORARY TABLE Temp_Ranking_Print_Author_Table (id int,ranking varchar(15));
    CREATE TEMPORARY TABLE Temp_Author_Fname (Fname text);
    CREATE TEMPORARY TABLE Temp_Author_Mname (Mname text);
    CREATE TEMPORARY TABLE Temp_Author_Lname (Lname text);
    CREATE TEMPORARY TABLE Temp_Header_Id (headerid int);
   
    WHILE fname != '' DO
    	SET element = SUBSTRING_INDEX(fname, ',', 1);
        
        IF element = 'nodata' THEN SET element = ''; END IF;
        
        INSERT INTO Temp_Author_Fname VALUES(element);
        
        IF LOCATE(',', fname) > 0 THEN
            SET fname = SUBSTRING(fname, LOCATE(',', fname) + 1);
        ELSE
            SET fname = '';
       	END IF;
    END WHILE;
    
    WHILE mname != '' DO
    	SET element = SUBSTRING_INDEX(mname, ',', 1);
        
        IF element = 'nodata' THEN SET element = ''; END IF;
        
        INSERT INTO Temp_Author_Mname VALUES(element);
        
        IF LOCATE(',', mname) > 0 THEN
            SET mname = SUBSTRING(mname, LOCATE(',', mname) + 1);
        ELSE
            SET mname = '';
       	END IF;
    END WHILE;
    
    WHILE lname != '' DO
    	SET element = SUBSTRING_INDEX(lname, ',', 1);
        
        IF element = 'nodata' THEN SET element = ''; END IF;
        
        INSERT INTO Temp_Author_Lname VALUES(element);
        
        IF LOCATE(',', lname) > 0 THEN
            SET lname = SUBSTRING(lname, LOCATE(',', lname) + 1);
        ELSE
            SET lname = '';
       	END IF;
    END WHILE;
    
    WHILE ranking != '' DO
    	SET element = SUBSTRING_INDEX(ranking, ',', 1);
      
        IF(element > 0) THEN
        	INSERT INTO Temp_Rankings_Print_Author VALUES(element);
        END IF;
        
        IF LOCATE(',', ranking) > 0 THEN
            SET ranking = SUBSTRING(ranking, LOCATE(',', ranking) + 1);
        ELSE
            SET ranking = '';
       	END IF;
    END WHILE;
    
    INSERT INTO Temp_Header_Id
    SELECT DISTINCT pubdtls.pubhdrid FROM  pubdtls WHERE IFNULL(pubdtls.athrfirstname COLLATE utf8mb4_unicode_ci,'') IN (SELECT * FROM Temp_Author_Fname)
    		AND IFNULL(pubdtls.athrmiddlename COLLATE utf8mb4_unicode_ci,'') IN (SELECT * FROM Temp_Author_Mname)
    		AND IFNULL(pubdtls.athrlastname COLLATE utf8mb4_unicode_ci,'') IN (SELECT * FROM Temp_Author_Lname);
            
    IF rankingcopy = 0 THEN /* when ranking not exists */

    		SELECT DISTINCT 
        		pubhdrs.pubdate,
        		pubdtls.pubhdrid, 
        		GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) AS slno,
        		/*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
                GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,
        		IFNULL(pubhdrs.title,'') AS title,
        		IFNULL(pubhdrs.confname,'') as conference,
        		IFNULL(pubhdrs.volume,'') as volume,
        		IFNULL(pubhdrs.issue,'') as issue,
                IFNULL(pubhdrs.pp,'') as pages,
                IFNULL(pubhdrs.nationality,'') AS nationality,
                IFNULL(pubhdrs.digitallibrary,'') AS Doi,
                IFNULL(art.article,'') AS article,
                IFNULL(rnk.ranking,'') as ranking, 
                IFNULL(brdarea.broadarea,'') as broadarea,
                IFNULL(pubhdrs.impactfactor,'') as impactfactor, 
                IFNULL(pubhdrs.place,'') AS location 
              FROM pubhdrs 
                INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
                LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
                LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid 
                /*LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid*/
                LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
                INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid  
                INNER JOIN categories ON categories.id = pubhdrs.categoryid 
              WHERE LOWER(categories.category) = CASE WHEN IFNULL(category,'') = '' THEN (categoryname COLLATE utf8mb4_unicode_ci) ELSE (category COLLATE utf8mb4_unicode_ci) END
                AND CASE WHEN (IFNULL(fromdate,'') != '' AND IFNULL(todate,'') != '') THEN pubhdrs.pubdate BETWEEN fromdate AND todate ELSE 1=1 END
                AND CASE WHEN authortypeid > 0 THEN authtype.id = authortypeid ELSE 1=1 END
                AND	CASE WHEN IFNULL(nationality,0) > 0 THEN pubhdrs.nationality = IFNULL(nationality,0) ELSE 1=1 END
                AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND pubdtls.pubhdrid IN (SELECT * FROM Temp_Header_Id)
                AND pubhdrs.deleted = 0
              GROUP by pubdtls.pubhdrid 
              order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;
       
	END IF;
    
    IF rankingcopy = 1 THEN /* when ranking exists */
    
    		INSERT INTO Temp_Ranking_Print_Author_Table
    		SELECT rnk.id,rnk.ranking from rankings rnk INNER JOIN Temp_Rankings_Print_Author tmprnk on rnk.id = tmprnk.rankingids;
    
    	   SELECT DISTINCT 
        		pubhdrs.pubdate,
        		pubdtls.pubhdrid, 
        		GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) AS slno,
        		/*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
                GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,
        		IFNULL(pubhdrs.title,'') AS title,
        		IFNULL(pubhdrs.confname,'') as conference,
        		IFNULL(pubhdrs.volume,'') as volume,
        		IFNULL(pubhdrs.issue,'') as issue,
                IFNULL(pubhdrs.pp,'') as pages,
                IFNULL(pubhdrs.nationality,'') AS nationality,
                IFNULL(pubhdrs.digitallibrary,'') AS Doi,
                IFNULL(art.article,'') AS article,
                IFNULL(rnk.ranking,'') as ranking, 
                IFNULL(brdarea.broadarea,'') as broadarea,
                IFNULL(pubhdrs.impactfactor,'') as impactfactor, 
                IFNULL(pubhdrs.place,'') AS location 
              FROM pubhdrs 
                INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
                INNER JOIN Temp_Ranking_Print_Author_Table rnk on rnk.id = pubhdrs.rankingid
                LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid 
                /*LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid*/ 
                LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
                INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid  
                INNER JOIN categories ON categories.id = pubhdrs.categoryid 
              WHERE LOWER(categories.category) = CASE WHEN IFNULL(category,'') = '' THEN (categoryname COLLATE utf8mb4_unicode_ci) ELSE (category COLLATE utf8mb4_unicode_ci) END
                AND CASE WHEN (IFNULL(fromdate,'') != '' AND IFNULL(todate,'') != '') THEN pubhdrs.pubdate BETWEEN fromdate AND todate ELSE 1=1 END
                AND CASE WHEN authortypeid > 0 THEN authtype.id = authortypeid ELSE 1=1 END
                AND	CASE WHEN IFNULL(nationality,0) > 0 THEN pubhdrs.nationality = IFNULL(nationality,0) ELSE 1=1 END
                AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND pubdtls.pubhdrid IN (SELECT * FROM Temp_Header_Id)
                AND pubhdrs.deleted = 0
              GROUP by pubdtls.pubhdrid 
              order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;
    
    END IF;

              
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Get_Author_Data_For_Update` (IN `hdrid` INT)  BEGIN

SELECT slno,IFNULL(dtls.athrfirstname,'') AS firstname, 
IFNULL(dtls.athrmiddlename,'') AS middlename, IFNULL(dtls.athrlastname,'') AS lastname, 
dtls.fullname 
FROM pubdtls dtls
WHERE dtls.pubhdrid = hdrid
ORDER BY slno;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Get_Autocmplete_Data` (IN `autotext` VARCHAR(50), IN `type` INT)  BEGIN

IF type = 1 THEN
	SELECT DISTINCT CONCAT(UPPER(SUBSTRING(pubhdrs.digitallibrary,1,1)),LOWER(SUBSTRING(pubhdrs.digitallibrary,2))) as autocomplete FROM pubhdrs
    WHERE pubhdrs.digitallibrary LIKE concat('%',autotext,'%')
    AND IFNULL(pubhdrs.digitallibrary,'') != '';

ELSEIF type = 2 THEN
	SELECT DISTINCT CONCAT(UPPER(SUBSTRING(pubhdrs.title,1,1)),LOWER(SUBSTRING(pubhdrs.title,2))) as autocomplete FROM pubhdrs
    WHERE pubhdrs.title LIKE concat('%',autotext,'%')
    AND IFNULL(pubhdrs.title,'') != '';

ELSEIF type = 3 THEN
	SELECT DISTINCT CONCAT(UPPER(SUBSTRING(pubhdrs.confname,1,1)),LOWER(SUBSTRING(pubhdrs.confname,2))) as autocomplete FROM pubhdrs
    WHERE pubhdrs.confname LIKE concat('%',autotext,'%')
    AND IFNULL(pubhdrs.confname,'') != '';
    
ELSEIF type = 4 THEN
	SELECT DISTINCT CONCAT(UPPER(SUBSTRING(pubhdrs.place,1,1)),LOWER(SUBSTRING(pubhdrs.place,2))) as autocomplete FROM pubhdrs
    WHERE pubhdrs.place LIKE concat('%',autotext,'%');

ELSEIF type = 5 THEN
	SELECT DISTINCT
CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2)) as autocomplete,
	IFNULL(athrfirstname,'') as fname, IFNULL(athrmiddlename,'') as mname,IFNULL(athrlastname,'') as lname from pubdtls
	where pubdtls.athrfirstname like concat('%',autotext,'%')
	or pubdtls.athrmiddlename like concat('%',autotext,'%')
	or pubdtls.athrlastname like concat('%',autotext,'%');

END IF;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Get_Print_Data` (IN `fromdt` DATE, IN `todt` DATE, IN `authortypeid` INT, IN `categoryid` INT, IN `nationality` INT, IN `title` TEXT, IN `conference` TEXT, IN `ranking` TEXT, IN `fname` VARCHAR(30), IN `mname` VARCHAR(30), IN `lname` VARCHAR(30), IN `categoryname` VARCHAR(25))  BEGIN


DECLARE required INT;
DECLARE element INT;
DECLARE authorelement varchar(30);

SET required = 0;

IF (IFNULL(fromdt,'') = '' AND IFNULL(todt,'') = '' AND IFNULL(authortypeid,0) = 0 AND IFNULL(categoryid,0) = 0
AND IFNULL(nationality,0) = 0 AND IFNULL(title,'') = '' AND IFNULL(conference,'') = '' AND IFNULL(ranking,'') = '0'
AND IFNULL(fname,'') = '' AND IFNULL(mname,'') = '' AND IFNULL(lname,'') = '') THEN
	SET required = 1;  
END IF;

IF ((IFNULL(fromdt,'') != '' AND IFNULL(todt,'') = '') OR (IFNULL(fromdt,'') = '' AND IFNULL(todt,'') != '')) THEN
	SET required = 1;
END IF;

IF ((IFNULL(fromdt,'') != '' AND IFNULL(todt,'') != '')) THEN
	SET required = 0;
END IF;

IF required = 0 THEN
    CREATE TEMPORARY TABLE Temp_Rankings (rankingids int);
    CREATE TEMPORARY TABLE Temp_Ranking_Table (id int,ranking varchar(15));
    
    CREATE TEMPORARY TABLE Temp_Author_Fname (Fname text);
    CREATE TEMPORARY TABLE Temp_Author_Mname (Mname text);
    CREATE TEMPORARY TABLE Temp_Author_Lname (Lname text);
    CREATE TEMPORARY TABLE Temp_Header_Id (headerid int);

    IF ranking = '' THEN SET ranking = ','; END IF;
    IF fname = '' THEN SET fname = ','; END IF;
    IF mname = '' THEN SET mname = ','; END IF;
    IF lname = '' THEN SET lname = ','; END IF;
    
    WHILE ranking != '' DO
    	SET element = SUBSTRING_INDEX(ranking, ',', 1);
      
        IF(element > 0) THEN
        	INSERT INTO Temp_Rankings VALUES(element);
        END IF;
        
        IF LOCATE(',', ranking) > 0 THEN
            SET ranking = SUBSTRING(ranking, LOCATE(',', ranking) + 1);
        ELSE
            SET ranking = '';
       	END IF;
    END WHILE;
    
    WHILE fname != '' DO
    	SET authorelement = SUBSTRING_INDEX(fname, ',', 1);
        
        IF authorelement = 'nodata' THEN SET authorelement = ''; END IF;
        
        INSERT INTO Temp_Author_Fname VALUES(authorelement);
        
        IF LOCATE(',', fname) > 0 THEN
            SET fname = SUBSTRING(fname, LOCATE(',', fname) + 1);
        ELSE
            SET fname = '';
       	END IF;
    END WHILE;
    
    WHILE mname != '' DO
    	SET authorelement = SUBSTRING_INDEX(mname, ',', 1);
        
        IF authorelement = 'nodata' THEN SET authorelement = ''; END IF;
        
        INSERT INTO Temp_Author_Mname VALUES(authorelement);
        
        IF LOCATE(',', mname) > 0 THEN
            SET mname = SUBSTRING(mname, LOCATE(',', mname) + 1);
        ELSE
            SET mname = '';

       	END IF;
    END WHILE;
    
    WHILE lname != '' DO
    	SET authorelement = SUBSTRING_INDEX(lname, ',', 1);
        
        IF authorelement = 'nodata' THEN SET authorelement = ''; END IF;
        
        INSERT INTO Temp_Author_Lname VALUES(authorelement);
        
        IF LOCATE(',', lname) > 0 THEN
            SET lname = SUBSTRING(lname, LOCATE(',', lname) + 1);
        ELSE
            SET lname = '';
       	END IF;
    END WHILE;
    
    INSERT INTO Temp_Header_Id
    SELECT DISTINCT pubdtls.pubhdrid FROM  pubdtls WHERE IFNULL(pubdtls.athrfirstname,'') IN (SELECT * FROM Temp_Author_Fname)
    		AND IFNULL(pubdtls.athrmiddlename,'') IN (SELECT * FROM Temp_Author_Mname)
    		AND IFNULL(pubdtls.athrlastname,'') IN (SELECT * FROM Temp_Author_Lname);
    
IF categoryid > 0 THEN  	/* category > 0 */

	 IF (EXISTS (SELECT 1 FROM Temp_Rankings) && NOT EXISTS (SELECT 1 FROM Temp_Header_Id)) THEN 
 		/* Ranking search exists and Author search not exists */
		SELECT 
       	hdr.pubdate,
  		dtls.pubhdrid,
        cat.category,
		GROUP_CONCAT(dtls.slno ORDER BY dtls.slno) as slno,  
		GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''),   2) ORDER BY dtls.slno) as authorname,
        IFNULL(hdr.title,'') AS title,
        IFNULL(hdr.confname,'') as conference,
        IFNULL(hdr.volume,'') as volume,
        IFNULL(hdr.issue,'') as issue,
        IFNULL(hdr.pp,'') as pages,
        IFNULL(hdr.nationality,'') AS nationality,
        IFNULL(hdr.digitallibrary,'') AS Doi,
        IFNULL(art.article,'') AS article,
		IFNULL(rnk.ranking,'') as ranking, 
        IFNULL(brdarea.broadarea,'') as broadarea,
		IFNULL(impact.impactfactor,'') as impactfactor, 
        IFNULL(hdr.place,'') AS location
  	FROM pubhdrs hdr 
  		INNER JOIN categories cat ON cat.id = hdr.categoryid 
  		INNER JOIN authortypes authtype ON authtype.id = hdr.authortypeid
  		LEFT OUTER JOIN articletypes art ON art.articleid = hdr.articletypeid
        LEFT OUTER JOIN rankings rnk on rnk.id = hdr.rankingid
  		RIGHT OUTER JOIN Temp_Rankings rank ON rnk.id = rank.rankingids
  		LEFT OUTER JOIN broadareas brdarea ON brdarea.id = hdr.broadareaid
  		LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid
  		INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid
  	WHERE cat.id = categoryid
    	AND CASE WHEN (IFNULL(fromdt,'') != '' AND IFNULL(todt,'') != '') THEN hdr.pubdate BETWEEN fromdt AND todt ELSE 1=1 END
    	AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(nationality,0) > 0 THEN hdr.nationality = IFNULL(nationality,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(title,'') != '' THEN hdr.title like concat('%',IFNULL(title,''),'%') ELSE 1=1 END
    	AND	CASE WHEN IFNULL(conference,'') != '' THEN hdr.confname like concat('%',IFNULL(conference,''),'%') ELSE 1=1 END
  	GROUP by hdr.id,hdr.pubdate
  	ORDER BY hdr.pubdate,hdr.id;
    
 ELSEIF (EXISTS (SELECT 1 FROM Temp_Header_Id) && NOT EXISTS (SELECT 1 FROM Temp_Rankings)) THEN
 	/* Ranking search not exists and Author search exists */
 	SELECT 
    	hdr.pubdate,
  		dtls.pubhdrid,
        cat.category,
		GROUP_CONCAT(dtls.slno ORDER BY dtls.slno) as slno,  
		GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''),   2) ORDER BY dtls.slno) as authorname,
        IFNULL(hdr.title,'') AS title,
        IFNULL(hdr.confname,'') as conference,
        IFNULL(hdr.volume,'') as volume,
        IFNULL(hdr.issue,'') as issue,
        IFNULL(hdr.pp,'') as pages,
        IFNULL(hdr.nationality,'') AS nationality,
        IFNULL(hdr.digitallibrary,'') AS Doi,
        IFNULL(art.article,'') AS article,
		IFNULL(rnk.ranking,'') as ranking, 
        IFNULL(brdarea.broadarea,'') as broadarea,
		IFNULL(impact.impactfactor,'') as impactfactor, 
        IFNULL(hdr.place,'') AS location
  	FROM pubhdrs hdr 
  		INNER JOIN categories cat ON cat.id = hdr.categoryid 
  		INNER JOIN authortypes authtype ON authtype.id = hdr.authortypeid
  		LEFT OUTER JOIN articletypes art ON art.articleid = hdr.articletypeid
        LEFT OUTER JOIN rankings rnk on rnk.id = hdr.rankingid
  		LEFT OUTER JOIN broadareas brdarea ON brdarea.id = hdr.broadareaid
  		LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid
  		INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid 
        INNER JOIN Temp_Header_Id thd ON thd.headerid = hdr.id
  	WHERE cat.id = categoryid
    	AND CASE WHEN (IFNULL(fromdt,'') != '' AND IFNULL(todt,'') != '') THEN hdr.pubdate BETWEEN fromdt AND todt ELSE 1=1 END
    	AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(nationality,0) > 0 THEN hdr.nationality = IFNULL(nationality,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(title,'') != '' THEN hdr.title like concat('%',IFNULL(title,''),'%') ELSE 1=1 END
    	AND	CASE WHEN IFNULL(conference,'') != '' THEN hdr.confname like concat('%',IFNULL(conference,''),'%') ELSE 1=1 END
  	GROUP by hdr.id,hdr.pubdate
  	ORDER BY hdr.pubdate,hdr.id;
    
 ELSEIF (EXISTS (SELECT 1 FROM Temp_Header_Id) && EXISTS (SELECT 1 FROM Temp_Rankings)) THEN
 	/* Ranking search exists and Author search exists */
    
    INSERT INTO Temp_Ranking_Table
    SELECT rnk.id,rnk.ranking from rankings rnk INNER JOIN Temp_Rankings tmprnk on rnk.id = tmprnk.rankingids;
    
 	SELECT 
    	hdr.pubdate,
  		dtls.pubhdrid,
        cat.category,
		GROUP_CONCAT(dtls.slno ORDER BY dtls.slno) as slno,  
		GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''),   2) ORDER BY dtls.slno) as authorname,
        IFNULL(hdr.title,'') AS title,
        IFNULL(hdr.confname,'') as conference,
        IFNULL(hdr.volume,'') as volume,
        IFNULL(hdr.issue,'') as issue,
        IFNULL(hdr.pp,'') as pages,
        IFNULL(hdr.nationality,'') AS nationality,
        IFNULL(hdr.digitallibrary,'') AS Doi,
        IFNULL(art.article,'') AS article,
		IFNULL(rnk.ranking,'') as ranking, 
        IFNULL(brdarea.broadarea,'') as broadarea,
		IFNULL(impact.impactfactor,'') as impactfactor, 
        IFNULL(hdr.place,'') AS location
  	FROM pubhdrs hdr 
  		INNER JOIN categories cat ON cat.id = hdr.categoryid 
  		INNER JOIN authortypes authtype ON authtype.id = hdr.authortypeid
  		LEFT OUTER JOIN articletypes art ON art.articleid = hdr.articletypeid
        INNER JOIN Temp_Ranking_Table rnk on rnk.id = hdr.rankingid
  		LEFT OUTER JOIN broadareas brdarea ON brdarea.id = hdr.broadareaid
  		LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid
  		INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid 
        INNER JOIN Temp_Header_Id thd ON thd.headerid = hdr.id
  	WHERE cat.id = categoryid
    	AND CASE WHEN (IFNULL(fromdt,'') != '' AND IFNULL(todt,'') != '') THEN hdr.pubdate BETWEEN fromdt AND todt ELSE 1=1 END
    	AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(nationality,0) > 0 THEN hdr.nationality = IFNULL(nationality,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(title,'') != '' THEN hdr.title like concat('%',IFNULL(title,''),'%') ELSE 1=1 END
    	AND	CASE WHEN IFNULL(conference,'') != '' THEN hdr.confname like concat('%',IFNULL(conference,''),'%') ELSE 1=1 END
  	GROUP by hdr.id,hdr.pubdate
  	ORDER BY hdr.pubdate,hdr.id;
   
 ELSE  
   	SELECT 
    	hdr.pubdate,
  		dtls.pubhdrid,
        cat.category,
		GROUP_CONCAT(dtls.slno ORDER BY dtls.slno) as slno,  
		GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''),   2) ORDER BY dtls.slno) as authorname,
        IFNULL(hdr.title,'') AS title,
        IFNULL(hdr.confname,'') as conference,
        IFNULL(hdr.volume,'') as volume,
        IFNULL(hdr.issue,'') as issue,
        IFNULL(hdr.pp,'') as pages,
        IFNULL(hdr.nationality,'') AS nationality,
        IFNULL(hdr.digitallibrary,'') AS Doi,
        IFNULL(art.article,'') AS article,
		IFNULL(rnk.ranking,'') as ranking, 
        IFNULL(brdarea.broadarea,'') as broadarea,
		IFNULL(impact.impactfactor,'') as impactfactor, 
        IFNULL(hdr.place,'') AS location
  	FROM pubhdrs hdr 
  		INNER JOIN categories cat ON cat.id = hdr.categoryid 
  		INNER JOIN authortypes authtype ON authtype.id = hdr.authortypeid
  		LEFT OUTER JOIN articletypes art ON art.articleid = hdr.articletypeid
        LEFT OUTER JOIN rankings rnk on rnk.id = hdr.rankingid
  		LEFT OUTER JOIN broadareas brdarea ON brdarea.id = hdr.broadareaid
  		LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid
  		INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid
  	WHERE cat.id = categoryid
    	AND CASE WHEN (IFNULL(fromdt,'') != '' AND IFNULL(todt,'') != '') THEN hdr.pubdate BETWEEN fromdt AND todt ELSE 1=1 END
    	AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(nationality,0) > 0 THEN hdr.nationality = IFNULL(nationality,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(title,'') != '' THEN hdr.title like concat('%',IFNULL(title,''),'%') ELSE 1=1 END
    	AND	CASE WHEN IFNULL(conference,'') != '' THEN hdr.confname like concat('%',IFNULL(conference,''),'%') ELSE 1=1 END
  	GROUP by hdr.id,hdr.pubdate
  	ORDER BY hdr.pubdate,hdr.id;
    
 END IF;   
    
 ELSEIF categoryid = 0 THEN /* category = 0 */  
 
 	IF (EXISTS (SELECT 1 FROM Temp_Rankings) && NOT EXISTS (SELECT 1 FROM Temp_Header_Id)) THEN 
 		/* Ranking search exists and Author search not exists */
		SELECT 
       	hdr.pubdate,
  		dtls.pubhdrid,
        cat.category,
		GROUP_CONCAT(dtls.slno ORDER BY dtls.slno) as slno,  
		GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''),   2) ORDER BY dtls.slno) as authorname,
        IFNULL(hdr.title,'') AS title,
        IFNULL(hdr.confname,'') as conference,
        IFNULL(hdr.volume,'') as volume,
        IFNULL(hdr.issue,'') as issue,
        IFNULL(hdr.pp,'') as pages,
        IFNULL(hdr.nationality,'') AS nationality,
        IFNULL(hdr.digitallibrary,'') AS Doi,
        IFNULL(art.article,'') AS article,
		IFNULL(rnk.ranking,'') as ranking, 
        IFNULL(brdarea.broadarea,'') as broadarea,
		IFNULL(impact.impactfactor,'') as impactfactor, 
        IFNULL(hdr.place,'') AS location
  	FROM pubhdrs hdr 
  		INNER JOIN categories cat ON cat.id = hdr.categoryid 
  		INNER JOIN authortypes authtype ON authtype.id = hdr.authortypeid
  		LEFT OUTER JOIN articletypes art ON art.articleid = hdr.articletypeid
        LEFT OUTER JOIN rankings rnk on rnk.id = hdr.rankingid
  		RIGHT OUTER JOIN Temp_Rankings rank ON rnk.id = rank.rankingids
  		LEFT OUTER JOIN broadareas brdarea ON brdarea.id = hdr.broadareaid
  		LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid
  		INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid
  	WHERE cat.category = categoryname
    	AND CASE WHEN (IFNULL(fromdt,'') != '' AND IFNULL(todt,'') != '') THEN hdr.pubdate BETWEEN fromdt AND todt ELSE 1=1 END
    	AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(nationality,0) > 0 THEN hdr.nationality = IFNULL(nationality,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(title,'') != '' THEN hdr.title like concat('%',IFNULL(title,''),'%') ELSE 1=1 END
    	AND	CASE WHEN IFNULL(conference,'') != '' THEN hdr.confname like concat('%',IFNULL(conference,''),'%') ELSE 1=1 END
  	GROUP by hdr.id,hdr.pubdate
  	ORDER BY hdr.pubdate,hdr.id;
    
 ELSEIF (EXISTS (SELECT 1 FROM Temp_Header_Id) && NOT EXISTS (SELECT 1 FROM Temp_Rankings)) THEN
 	/* Ranking search not exists and Author search exists */
 	SELECT 
    	hdr.pubdate,
  		dtls.pubhdrid,
        cat.category,
		GROUP_CONCAT(dtls.slno ORDER BY dtls.slno) as slno,  
		GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''),   2) ORDER BY dtls.slno) as authorname,
        IFNULL(hdr.title,'') AS title,
        IFNULL(hdr.confname,'') as conference,
        IFNULL(hdr.volume,'') as volume,
        IFNULL(hdr.issue,'') as issue,
        IFNULL(hdr.pp,'') as pages,
        IFNULL(hdr.nationality,'') AS nationality,
        IFNULL(hdr.digitallibrary,'') AS Doi,
        IFNULL(art.article,'') AS article,
		IFNULL(rnk.ranking,'') as ranking, 
        IFNULL(brdarea.broadarea,'') as broadarea,
		IFNULL(impact.impactfactor,'') as impactfactor, 
        IFNULL(hdr.place,'') AS location
  	FROM pubhdrs hdr 
  		INNER JOIN categories cat ON cat.id = hdr.categoryid 
  		INNER JOIN authortypes authtype ON authtype.id = hdr.authortypeid
  		LEFT OUTER JOIN articletypes art ON art.articleid = hdr.articletypeid
        LEFT OUTER JOIN rankings rnk on rnk.id = hdr.rankingid
  		LEFT OUTER JOIN broadareas brdarea ON brdarea.id = hdr.broadareaid
  		LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid
  		INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid 
        INNER JOIN Temp_Header_Id thd ON thd.headerid = hdr.id
  	WHERE LOWER(cat.category) = categoryname
    	AND CASE WHEN (IFNULL(fromdt,'') != '' AND IFNULL(todt,'') != '') THEN hdr.pubdate BETWEEN fromdt AND todt ELSE 1=1 END
    	AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(nationality,0) > 0 THEN hdr.nationality = IFNULL(nationality,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(title,'') != '' THEN hdr.title like concat('%',IFNULL(title,''),'%') ELSE 1=1 END
    	AND	CASE WHEN IFNULL(conference,'') != '' THEN hdr.confname like concat('%',IFNULL(conference,''),'%') ELSE 1=1 END
  	GROUP by hdr.id,hdr.pubdate
  	ORDER BY hdr.pubdate,hdr.id;
    
 ELSEIF (EXISTS (SELECT 1 FROM Temp_Header_Id) && EXISTS (SELECT 1 FROM Temp_Rankings)) THEN
 	/* Ranking search exists and Author search exists */
    
    INSERT INTO Temp_Ranking_Table
    SELECT rnk.id,rnk.ranking from rankings rnk INNER JOIN Temp_Rankings tmprnk on rnk.id = tmprnk.rankingids;
    
 	SELECT hdr.pubdate,
  		dtls.pubhdrid,
        cat.category,
		GROUP_CONCAT(dtls.slno ORDER BY dtls.slno) as slno,  
		GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''),   2) ORDER BY dtls.slno) as authorname,
        IFNULL(hdr.title,'') AS title,
        IFNULL(hdr.confname,'') as conference,
        IFNULL(hdr.volume,'') as volume,
        IFNULL(hdr.issue,'') as issue,
        IFNULL(hdr.pp,'') as pages,
        IFNULL(hdr.nationality,'') AS nationality,
        IFNULL(hdr.digitallibrary,'') AS Doi,
        IFNULL(art.article,'') AS article,
		IFNULL(rnk.ranking,'') as ranking, 
        IFNULL(brdarea.broadarea,'') as broadarea,
		IFNULL(impact.impactfactor,'') as impactfactor, 
        IFNULL(hdr.place,'') AS location
  	FROM pubhdrs hdr 
  		INNER JOIN categories cat ON cat.id = hdr.categoryid 
  		INNER JOIN authortypes authtype ON authtype.id = hdr.authortypeid
  		LEFT OUTER JOIN articletypes art ON art.articleid = hdr.articletypeid
        INNER JOIN Temp_Ranking_Table rnk on rnk.id = hdr.rankingid
  		LEFT OUTER JOIN broadareas brdarea ON brdarea.id = hdr.broadareaid
  		LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid
  		INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid 
        INNER JOIN Temp_Header_Id thd ON thd.headerid = hdr.id
  	WHERE LOWER(cat.category) = categoryname
    	AND CASE WHEN (IFNULL(fromdt,'') != '' AND IFNULL(todt,'') != '') THEN hdr.pubdate BETWEEN fromdt AND todt ELSE 1=1 END
    	AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(nationality,0) > 0 THEN hdr.nationality = IFNULL(nationality,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(title,'') != '' THEN hdr.title like concat('%',IFNULL(title,''),'%') ELSE 1=1 END
    	AND	CASE WHEN IFNULL(conference,'') != '' THEN hdr.confname like concat('%',IFNULL(conference,''),'%') ELSE 1=1 END
  	GROUP by hdr.id,hdr.pubdate
  	ORDER BY hdr.pubdate,hdr.id;
   
 ELSE  
   	SELECT 
    	hdr.pubdate,
  		dtls.pubhdrid,
        cat.category,
		GROUP_CONCAT(dtls.slno ORDER BY dtls.slno) as slno,  
		GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''),   2) ORDER BY dtls.slno) as authorname,
        IFNULL(hdr.title,'') AS title,
        IFNULL(hdr.confname,'') as conference,
        IFNULL(hdr.volume,'') as volume,
        IFNULL(hdr.issue,'') as issue,
        IFNULL(hdr.pp,'') as pages,
        IFNULL(hdr.nationality,'') AS nationality,
        IFNULL(hdr.digitallibrary,'') AS Doi,
        IFNULL(art.article,'') AS article,
		IFNULL(rnk.ranking,'') as ranking, 
        IFNULL(brdarea.broadarea,'') as broadarea,
		IFNULL(impact.impactfactor,'') as impactfactor, 
        IFNULL(hdr.place,'') AS location
  	FROM pubhdrs hdr 
  		INNER JOIN categories cat ON cat.id = hdr.categoryid 
  		INNER JOIN authortypes authtype ON authtype.id = hdr.authortypeid
  		LEFT OUTER JOIN articletypes art ON art.articleid = hdr.articletypeid
        LEFT OUTER JOIN rankings rnk on rnk.id = hdr.rankingid
  		LEFT OUTER JOIN broadareas brdarea ON brdarea.id = hdr.broadareaid
  		LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid
  		INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid
  	WHERE LOWER(cat.category) = categoryname
    	AND CASE WHEN (IFNULL(fromdt,'') != '' AND IFNULL(todt,'') != '') THEN hdr.pubdate BETWEEN fromdt AND todt ELSE 1=1 END
    	AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(nationality,0) > 0 THEN hdr.nationality = IFNULL(nationality,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(title,'') != '' THEN hdr.title like concat('%',IFNULL(title,''),'%') ELSE 1=1 END
    	AND	CASE WHEN IFNULL(conference,'') != '' THEN hdr.confname like concat('%',IFNULL(conference,''),'%') ELSE 1=1 END
  	GROUP by hdr.id,hdr.pubdate
  	ORDER BY hdr.pubdate,hdr.id;
    
 END IF; 

END IF;
   
 DROP TEMPORARY TABLE IF EXISTS Temp_Rankings;
 DROP TEMPORARY TABLE IF EXISTS Temp_Ranking_Table;
 DROP TEMPORARY TABLE IF EXISTS Temp_Author_Fname;
 DROP TEMPORARY TABLE IF EXISTS Temp_Author_Mname;
 DROP TEMPORARY TABLE IF EXISTS Temp_Author_Lname;
 DROP TEMPORARY TABLE IF EXISTS Temp_Header_Id;
   
 END IF;
 
 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Get_Search_Data` (IN `fromdt` DATE, IN `todt` DATE, IN `authortypeid` INT, IN `categoryid` INT, IN `nationality` INT, IN `title` TEXT, IN `conference` TEXT, IN `ranking` TEXT, IN `fname` VARCHAR(30), IN `mname` VARCHAR(30), IN `lname` VARCHAR(30))  BEGIN

BEGIN

DECLARE required INT;
DECLARE element INT;
DECLARE authorelement varchar(30);

SET required = 0;

IF (IFNULL(fromdt,'') = '' AND IFNULL(todt,'') = '' AND IFNULL(authortypeid,0) = 0 AND IFNULL(categoryid,0) = 0
AND IFNULL(nationality,0) = 0 AND IFNULL(title,'') = '' AND IFNULL(conference,'') = '' AND IFNULL(ranking,'') = '0'
AND IFNULL(fname,'') = '' AND IFNULL(mname,'') = '' AND IFNULL(lname,'') = '') THEN
	SET required = 1;  
END IF;

IF ((IFNULL(fromdt,'') != '' AND IFNULL(todt,'') = '') OR (IFNULL(fromdt,'') = '' AND IFNULL(todt,'') != '')) THEN
	SET required = 1;
END IF;

IF ((IFNULL(fromdt,'') != '' AND IFNULL(todt,'') != '')) THEN
	SET required = 0;
END IF;

IF required = 0 THEN
    CREATE TEMPORARY TABLE Temp_Rankings (rankingids int);
    CREATE TEMPORARY TABLE Temp_Ranking_Table (id int,ranking varchar(15));
    
    CREATE TEMPORARY TABLE Temp_Author_Fname (Fname text);
    CREATE TEMPORARY TABLE Temp_Author_Mname (Mname text);
    CREATE TEMPORARY TABLE Temp_Author_Lname (Lname text);
    CREATE TEMPORARY TABLE Temp_Header_Id (headerid int);

    IF ranking = '' THEN SET ranking = ','; END IF;
    IF fname = '' THEN SET fname = ','; END IF;
    IF mname = '' THEN SET mname = ','; END IF;
    IF lname = '' THEN SET lname = ','; END IF;
    
    WHILE ranking != '' DO
    	SET element = SUBSTRING_INDEX(ranking, ',', 1);
      
        IF(element > 0) THEN
        	INSERT INTO Temp_Rankings VALUES(element);
        END IF;
        
        IF LOCATE(',', ranking) > 0 THEN
            SET ranking = SUBSTRING(ranking, LOCATE(',', ranking) + 1);
        ELSE
            SET ranking = '';
       	END IF;
    END WHILE;
    
    WHILE fname != '' DO
    	SET authorelement = SUBSTRING_INDEX(fname, ',', 1);
        
        IF authorelement = 'nodata' THEN SET authorelement = ''; END IF;
        
        INSERT INTO Temp_Author_Fname VALUES(authorelement);
        
        IF LOCATE(',', fname) > 0 THEN
            SET fname = SUBSTRING(fname, LOCATE(',', fname) + 1);
        ELSE
            SET fname = '';
       	END IF;
    END WHILE;
    
    WHILE mname != '' DO
    	SET authorelement = SUBSTRING_INDEX(mname, ',', 1);
        
        IF authorelement = 'nodata' THEN SET authorelement = ''; END IF;
        
        INSERT INTO Temp_Author_Mname VALUES(authorelement);
        
        IF LOCATE(',', mname) > 0 THEN
            SET mname = SUBSTRING(mname, LOCATE(',', mname) + 1);
        ELSE
            SET mname = '';

       	END IF;
    END WHILE;
    
    WHILE lname != '' DO
    	SET authorelement = SUBSTRING_INDEX(lname, ',', 1);
        
        IF authorelement = 'nodata' THEN SET authorelement = ''; END IF;
        
        INSERT INTO Temp_Author_Lname VALUES(authorelement);
        
        IF LOCATE(',', lname) > 0 THEN
            SET lname = SUBSTRING(lname, LOCATE(',', lname) + 1);
        ELSE
            SET lname = '';
       	END IF;
    END WHILE;
    
    INSERT INTO Temp_Header_Id
    SELECT DISTINCT pubdtls.pubhdrid FROM  pubdtls WHERE IFNULL(pubdtls.athrfirstname COLLATE utf8mb4_unicode_ci,'') IN (SELECT * FROM Temp_Author_Fname)
    		AND IFNULL(pubdtls.athrmiddlename COLLATE utf8mb4_unicode_ci,'') IN (SELECT * FROM Temp_Author_Mname)
    		AND IFNULL(pubdtls.athrlastname COLLATE utf8mb4_unicode_ci,'') IN (SELECT * FROM Temp_Author_Lname);
    
 IF (EXISTS (SELECT 1 FROM Temp_Rankings) && NOT EXISTS (SELECT 1 FROM Temp_Header_Id)) THEN 
 		/* Ranking search exists and Author search not exists */
		SELECT hdr.id as hdrid, DATE_FORMAT(hdr.pubdate, "%d/%m/%Y") as publicationdate,
  		CONCAT(UPPER(SUBSTRING(authtype.authortype,1,1)),LOWER(SUBSTRING(authtype.authortype,2))) as authortype,
  		CONCAT(UPPER(SUBSTRING(cat.category,1,1)),LOWER(SUBSTRING(cat.category,2))) as category,
  		hdr.nationality,
  		IFNULL(article.article,'') as article,
  		IFNULL(rnk.ranking,'') as ranking,
  		IFNULL(brdar.broadarea,'') as broadarea,
  		IFNULL(hdr.impactfactor,'') as impactfactor,
  		IFNULL(hdr.title,'') as title,
  		IFNULL(hdr.confname,'') as confname,
  		IFNULL(hdr.place,'') as location,
  		IFNULL(hdr.volume,'') as volume,
  		IFNULL(hdr.issue,'') as issue,
  		IFNULL(hdr.pp,'') as pp,
  		IFNULL(hdr.digitallibrary,'') as doi,
        
         GROUP_CONCAT(UCASE(LEFT(IFNULL(dtls.athrfirstname,''),1)),SUBSTRING(IFNULL(dtls.athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(dtls.athrmiddlename,''), 1)),SUBSTRING(IFNULL(dtls.athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(dtls.athrlastname,''), 1)),SUBSTRING(IFNULL(dtls.athrlastname,''), 2) ORDER BY dtls.slno) as authorname, hdr.userid as userid
  	FROM pubhdrs hdr 
  		INNER JOIN categories cat ON cat.id = hdr.categoryid 
  		INNER JOIN authortypes authtype ON authtype.id = hdr.authortypeid
  		LEFT OUTER JOIN articletypes article ON article.articleid = hdr.articletypeid
        LEFT OUTER JOIN rankings rnk on rnk.id = hdr.rankingid
  		RIGHT OUTER JOIN Temp_Rankings rank ON rnk.id = rank.rankingids
  		LEFT OUTER JOIN broadareas brdar ON brdar.id = hdr.broadareaid
  		/*LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid*/
  		INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid
  	WHERE
    	CASE WHEN (IFNULL(fromdt,'') != '' AND IFNULL(todt,'') != '') THEN hdr.pubdate BETWEEN fromdt AND todt ELSE 1=1 END
    	AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
    	AND CASE WHEN IFNULL(categoryid,0) > 0 THEN cat.id = IFNULL(categoryid,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(nationality,0) > 0 THEN hdr.nationality = IFNULL(nationality,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN hdr.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
    	AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN hdr.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
    AND hdr.deleted = 0    
  	GROUP by hdr.id,hdr.pubdate
  	ORDER BY hdr.pubdate,hdr.id;
    
 ELSEIF (EXISTS (SELECT 1 FROM Temp_Header_Id) && NOT EXISTS (SELECT 1 FROM Temp_Rankings)) THEN
 	/* Ranking search not exists and Author search exists */
 	SELECT hdr.id as hdrid, DATE_FORMAT(hdr.pubdate, "%d/%m/%Y") as publicationdate,
  		CONCAT(UPPER(SUBSTRING(authtype.authortype,1,1)),LOWER(SUBSTRING(authtype.authortype,2))) as authortype,
  		CONCAT(UPPER(SUBSTRING(cat.category,1,1)),LOWER(SUBSTRING(cat.category,2))) as category,
  		hdr.nationality,
  		IFNULL(article.article,'') as article,
  		IFNULL(rnk.ranking,'') as ranking,
  		IFNULL(brdar.broadarea,'') as broadarea,
  		IFNULL(hdr.impactfactor,'') as impactfactor,
  		IFNULL(hdr.title,'') as title,
  		IFNULL(hdr.confname,'') as confname,
  		IFNULL(hdr.place,'') as location,
  		IFNULL(hdr.volume,'') as volume,
  		IFNULL(hdr.issue,'') as issue,
  		IFNULL(hdr.pp,'') as pp,
  		IFNULL(hdr.digitallibrary,'') as doi, 
        
        GROUP_CONCAT(UCASE(LEFT(IFNULL(dtls.athrfirstname,''),1)),SUBSTRING(IFNULL(dtls.athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(dtls.athrmiddlename,''), 1)),SUBSTRING(IFNULL(dtls.athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(dtls.athrlastname,''), 1)),SUBSTRING(IFNULL(dtls.athrlastname,''), 2) ORDER BY dtls.slno) as authorname, hdr.userid as userid
  	FROM pubhdrs hdr 
  		INNER JOIN categories cat ON cat.id = hdr.categoryid 
  		INNER JOIN authortypes authtype ON authtype.id = hdr.authortypeid
  		LEFT OUTER JOIN articletypes article ON article.articleid = hdr.articletypeid
        LEFT OUTER JOIN rankings rnk on rnk.id = hdr.rankingid
  		LEFT OUTER JOIN broadareas brdar ON brdar.id = hdr.broadareaid
  		/*LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid*/
  		INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid 
        INNER JOIN Temp_Header_Id thd ON thd.headerid = hdr.id
  	WHERE
    	CASE WHEN (IFNULL(fromdt,'') != '' AND IFNULL(todt,'') != '') THEN hdr.pubdate BETWEEN fromdt AND todt ELSE 1=1 END
    	AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
    	AND CASE WHEN IFNULL(categoryid,0) > 0 THEN cat.id = IFNULL(categoryid,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(nationality,0) > 0 THEN hdr.nationality = IFNULL(nationality,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN hdr.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
    	AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN hdr.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
    AND hdr.deleted = 0    
  	GROUP by hdr.id,hdr.pubdate
  	ORDER BY hdr.pubdate,hdr.id;
    
 ELSEIF (EXISTS (SELECT 1 FROM Temp_Header_Id) && EXISTS (SELECT 1 FROM Temp_Rankings)) THEN
 	/* Ranking search exists and Author search exists */
    
    INSERT INTO Temp_Ranking_Table
    SELECT rnk.id,rnk.ranking from rankings rnk INNER JOIN Temp_Rankings tmprnk on rnk.id = tmprnk.rankingids;
    
 	SELECT hdr.id as hdrid, DATE_FORMAT(hdr.pubdate, "%d/%m/%Y") as publicationdate,
  		CONCAT(UPPER(SUBSTRING(authtype.authortype,1,1)),LOWER(SUBSTRING(authtype.authortype,2))) as authortype,
  		CONCAT(UPPER(SUBSTRING(cat.category,1,1)),LOWER(SUBSTRING(cat.category,2))) as category,
  		hdr.nationality,
  		IFNULL(article.article,'') as article,
  		IFNULL(rnk.ranking,'') as ranking,
  		IFNULL(brdar.broadarea,'') as broadarea,
  		IFNULL(hdr.impactfactor,'') as impactfactor,
  		IFNULL(hdr.title,'') as title,
  		IFNULL(hdr.confname,'') as confname,
  		IFNULL(hdr.place,'') as location,
  		IFNULL(hdr.volume,'') as volume,
  		IFNULL(hdr.issue,'') as issue,
  		IFNULL(hdr.pp,'') as pp,
  		IFNULL(hdr.digitallibrary,'') as doi,
        
		GROUP_CONCAT(UCASE(LEFT(IFNULL(dtls.athrfirstname,''),1)),SUBSTRING(IFNULL(dtls.athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(dtls.athrmiddlename,''), 1)),SUBSTRING(IFNULL(dtls.athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(dtls.athrlastname,''), 1)),SUBSTRING(IFNULL(dtls.athrlastname,''), 2) ORDER BY dtls.slno) as authorname, hdr.userid as userid
  	FROM pubhdrs hdr 
  		INNER JOIN categories cat ON cat.id = hdr.categoryid 
  		INNER JOIN authortypes authtype ON authtype.id = hdr.authortypeid
  		LEFT OUTER JOIN articletypes article ON article.articleid = hdr.articletypeid
        INNER JOIN Temp_Ranking_Table rnk on rnk.id = hdr.rankingid
  		LEFT OUTER JOIN broadareas brdar ON brdar.id = hdr.broadareaid
  		/*LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid*/
  		INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid 
        INNER JOIN Temp_Header_Id thd ON thd.headerid = hdr.id
  	WHERE
    	CASE WHEN (IFNULL(fromdt,'') != '' AND IFNULL(todt,'') != '') THEN hdr.pubdate BETWEEN fromdt AND todt ELSE 1=1 END
    	AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
    	AND CASE WHEN IFNULL(categoryid,0) > 0 THEN cat.id = IFNULL(categoryid,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(nationality,0) > 0 THEN hdr.nationality = IFNULL(nationality,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN hdr.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
    	AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN hdr.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
    AND hdr.deleted = 0    
  	GROUP by hdr.id,hdr.pubdate
  	ORDER BY hdr.pubdate,hdr.id;
   
 ELSE  
   	SELECT hdr.id as hdrid, DATE_FORMAT(hdr.pubdate, "%d/%m/%Y") as publicationdate,
  		CONCAT(UPPER(SUBSTRING(authtype.authortype,1,1)),LOWER(SUBSTRING(authtype.authortype,2))) as authortype,
  		CONCAT(UPPER(SUBSTRING(cat.category,1,1)),LOWER(SUBSTRING(cat.category,2))) as category,
  		hdr.nationality,
  		IFNULL(article.article,'') as article,
  		IFNULL(rnk.ranking,'') as ranking,
  		IFNULL(brdar.broadarea,'') as broadarea,
  		IFNULL(hdr.impactfactor,'') as impactfactor,
  		IFNULL(hdr.title,'') as title,
  		IFNULL(hdr.confname,'') as confname,
  		IFNULL(hdr.place,'') as location,
  		IFNULL(hdr.volume,'') as volume,
  		IFNULL(hdr.issue,'') as issue,
  		IFNULL(hdr.pp,'') as pp,
  		IFNULL(hdr.digitallibrary,'') as doi, 
        
        GROUP_CONCAT(UCASE(LEFT(IFNULL(dtls.athrfirstname,''),1)),SUBSTRING(IFNULL(dtls.athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(dtls.athrmiddlename,''), 1)),SUBSTRING(IFNULL(dtls.athrmiddlename,''), 2),' ', UCASE(LEFT(IFNULL(dtls.athrlastname,''), 1)),SUBSTRING(IFNULL(dtls.athrlastname,''), 2) ORDER BY dtls.slno) as authorname, hdr.userid as userid
  	FROM pubhdrs hdr 
  		INNER JOIN categories cat ON cat.id = hdr.categoryid 
  		INNER JOIN authortypes authtype ON authtype.id = hdr.authortypeid
  		LEFT OUTER JOIN articletypes article ON article.articleid = hdr.articletypeid
        LEFT OUTER JOIN rankings rnk on rnk.id = hdr.rankingid
  		LEFT OUTER JOIN broadareas brdar ON brdar.id = hdr.broadareaid
  		/*LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid*/
  		INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid
  	WHERE
    	CASE WHEN (IFNULL(fromdt,'') != '' AND IFNULL(todt,'') != '') THEN hdr.pubdate BETWEEN fromdt AND todt ELSE 1=1 END
    	AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
    	AND CASE WHEN IFNULL(categoryid,0) > 0 THEN cat.id = IFNULL(categoryid,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(nationality,0) > 0 THEN hdr.nationality = IFNULL(nationality,0) ELSE 1=1 END
    	AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN hdr.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
    	AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN hdr.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
    AND hdr.deleted = 0    
  	GROUP by hdr.id,hdr.pubdate
  	ORDER BY hdr.pubdate,hdr.id;
    
 END IF;   
   
 DROP TEMPORARY TABLE IF EXISTS Temp_Rankings;
 DROP TEMPORARY TABLE IF EXISTS Temp_Ranking_Table;
 DROP TEMPORARY TABLE IF EXISTS Temp_Author_Fname;
 DROP TEMPORARY TABLE IF EXISTS Temp_Author_Mname;
 DROP TEMPORARY TABLE IF EXISTS Temp_Author_Lname;
 DROP TEMPORARY TABLE IF EXISTS Temp_Header_Id;
   
 END IF;
 
END;
 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Get_Search_View_Data` (IN `fromdt` TEXT, IN `todt` TEXT, IN `authorname` VARCHAR(350), IN `category` INT)  BEGIN

DECLARE required INT;
DECLARE element INT;
DECLARE authorelement varchar(30);

SET required = 0;

IF (IFNULL(fromdt,'') = '' AND IFNULL(todt,'') = '' AND IFNULL(authorname,'') = '') THEN
	SET required = 1;  
END IF;

IF required = 0 THEN
    CREATE TEMPORARY TABLE Temp_Header_Id (headerid int);
    
    INSERT INTO Temp_Header_Id
    SELECT DISTINCT pubdtls.pubhdrid FROM  pubdtls WHERE IFNULL(pubdtls.fullname,'') like concat('%',IFNULL(authorname COLLATE utf8mb4_unicode_ci,''),'%');
    
   	SELECT hdr.id as hdrid, DATE_FORMAT(hdr.pubdate, "%d/%m/%Y") as publicationdate,cat.category,
    	GROUP_CONCAT(CASE WHEN dtls.slno != 1 THEN concat(" ",dtls.fullname) ELSE dtls.fullname END ORDER BY dtls.slno) as authorname,
  		IFNULL(hdr.title,'') as title,
  		IFNULL(hdr.confname,'') as confname
  	FROM pubhdrs hdr
    	INNER JOIN categories cat ON cat.id = hdr.categoryid
    	INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid
  		INNER JOIN Temp_Header_Id temp ON temp.headerid = hdr.id
   	WHERE hdr.deleted = 0  
   		AND YEAR(hdr.pubdate) BETWEEN fromdt AND todt
        AND	CASE WHEN IFNULL(category,0) != 0 THEN cat.id = category ELSE 1=1 END
    GROUP by dtls.pubhdrid
  	ORDER BY hdr.pubdate,hdr.id;

   DROP TEMPORARY TABLE IF EXISTS Temp_Header_Id;
   
 END IF;
 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Get_update_Data` (IN `hdrid` INT)  BEGIN

SELECT hdr.id,hdr.pubdate,hdr.authortypeid,
CONCAT(UPPER(SUBSTRING(ath.authortype,1,1)),LOWER(SUBSTRING(ath.authortype,2))) AS authortype,
hdr.categoryid,
CONCAT(UPPER(SUBSTRING(cat.category,1,1)),LOWER(SUBSTRING(cat.category,2))) AS category,
hdr.nationality,
hdr.digitallibrary AS doi,
hdr.articletypeid AS articletypeid,
IFNULL(article.article,'') AS article,
hdr.rankingid,
IFNULL(rnk.ranking,'') AS ranking,
hdr.broadareaid,
IFNULL(brd.broadarea,'') AS broadarea,
IFNULL(hdr.impactfactor,'') AS impactfactor,
IFNULL(hdr.place,'') AS location,
IFNULL(hdr.title,'') AS title,
IFNULL(hdr.confname,'') AS confname,
IFNULL(hdr.volume,'') AS volume,IFNULL(hdr.issue,'') AS issue,IFNULL(hdr.pp,'') AS pp,
IFNULL(hdr.publisher,'') AS publisher
FROM pubhdrs hdr
INNER JOIN authortypes ath ON ath.id = hdr.authortypeid
INNER JOIN categories cat ON cat.id = hdr.categoryid
LEFT OUTER JOIN rankings rnk ON rnk.id = hdr.rankingid
LEFT OUTER JOIN broadareas brd ON brd.id = hdr.broadareaid
/*LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid*/
LEFT OUTER JOIN articletypes article ON article.articleid = hdr.articletypeid
WHERE hdr.id = hdrid;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Print_Publication_Data` (IN `fromdate` DATE, IN `todate` DATE, IN `category` VARCHAR(25), IN `nationality` INT, IN `fname` TEXT, IN `mname` TEXT, IN `lname` TEXT, IN `type` INT, IN `subtype` INT, IN `categoryname` VARCHAR(25), IN `authortypeid` INT, IN `title` TEXT, IN `conference` TEXT, IN `ranking` TEXT)  BEGIN

DECLARE rankingcopy int;
DECLARE element INT;

CREATE TEMPORARY TABLE Temp_Rankings_Print (rankingids int);

IF CONVERT(ranking,int) = 0 THEN 
	SET rankingcopy = 0; 
ELSE 
	SET rankingcopy = 1; 
END IF;

IF rankingcopy = 0 AND type <> 8 THEN /* ranking and author condition */
	IF type = 0 THEN /* All search criteria */

          SELECT hdr.pubdate,dtls.pubhdrid,cat.category,
        GROUP_CONCAT(dtls.slno ORDER BY dtls.slno) as slno,  
        /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''),   2) ORDER BY dtls.slno)*/
        GROUP_CONCAT(CASE WHEN dtls.slno != 1 THEN concat(" ",dtls.fullname) ELSE dtls.fullname END ORDER BY dtls.slno) as authorname,IFNULL(hdr.title,'') AS title,IFNULL(hdr.confname,'') as conference,IFNULL(hdr.volume,'') as volume,IFNULL(hdr.issue,'') as issue,IFNULL(hdr.pp,'') as pages, IFNULL(hdr.nationality,'') AS nationality,IFNULL(hdr.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article,
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(hdr.impactfactor,'') as impactfactor, IFNULL(hdr.place,'') AS location
           FROM pubhdrs hdr
           INNER JOIN categories cat ON cat.id = hdr.categoryid
           LEFT OUTER JOIN articletypes art ON art.articleid = hdr.articletypeid 
           LEFT OUTER JOIN rankings rnk ON rnk.id = hdr.rankingid
           LEFT OUTER JOIN broadareas brdarea ON brdarea.id = hdr.broadareaid
           /*LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid*/
           INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid
           INNER JOIN authortypes authtype ON authtype.id = hdr.authortypeid
           WHERE LOWER(cat.category) IN (categoryname COLLATE utf8mb4_unicode_ci)
           AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
           AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN hdr.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN hdr.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND hdr.deleted = 0     
           GROUP by dtls.pubhdrid
           order by IFNULL(hdr.nationality,''),pubdate,pubhdrid;

    ELSEIF type = 1 THEN /* Date search criteria */

          SELECT pubhdrs.pubdate,pubdtls.pubhdrid,categories.category,
          GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) as slno,
          /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),'  ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
          GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,IFNULL(pubhdrs.title,'') AS title,IFNULL(pubhdrs.confname,'') as conference,IFNULL(pubhdrs.volume,'') AS volume,IFNULL(pubhdrs.issue,'') as issue,IFNULL(pubhdrs.pp,'') as pages, IFNULL(pubhdrs.nationality,'') AS nationality,
        IFNULL(pubhdrs.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article,
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(pubhdrs.impactfactor,'') as impactfactor, IFNULL(pubhdrs.place,'') AS location
           FROM pubhdrs INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
           INNER JOIN categories ON categories.id = pubhdrs.categoryid
           INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid
           LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
           LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
           LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid
           /*LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid*/
           where pubdate BETWEEN fromdate and todate
           AND LOWER(categories.category) IN (categoryname COLLATE utf8mb4_unicode_ci)
           AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
           AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND pubhdrs.deleted = 0     
           GROUP by pubdtls.pubhdrid
           order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;

    ELSEIF type = 2 THEN /* Category, Date criteria */

         SELECT pubhdrs.pubdate,pubdtls.pubhdrid,
         GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) as slno,
         /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
         GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,IFNULL(pubhdrs.title,'') AS title,IFNULL(pubhdrs.confname,'') as conference,IFNULL(pubhdrs.volume,'') as volume,IFNULL(pubhdrs.issue,'') as issue,IFNULL(pubhdrs.pp,'') as pages, IFNULL(pubhdrs.nationality,'') AS nationality,
        IFNULL(pubhdrs.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article,
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(pubhdrs.impactfactor,'') as impactfactor, IFNULL(pubhdrs.place,'') AS location
        FROM pubhdrs INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
        INNER JOIN categories ON categories.id = pubhdrs.categoryid
        INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid
        LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
        LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
        LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid
        /*LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid*/
        where pubdate BETWEEN fromdate and todate
        and categories.category IN (category COLLATE utf8mb4_unicode_ci)
        AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
          AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND pubhdrs.deleted = 0     
           GROUP by pubdtls.pubhdrid
           order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;

    ELSEIF type = 3 THEN /* Nationality, Date criteria */

         SELECT pubhdrs.pubdate,pubdtls.pubhdrid,
         GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) as slno,
         /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
         GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,IFNULL(pubhdrs.title,'') AS title,IFNULL(pubhdrs.confname,'') as conference,IFNULL(pubhdrs.volume,'') as volume,IFNULL(pubhdrs.issue,'') as issue,IFNULL(pubhdrs.pp,'') as pages, IFNULL(pubhdrs.nationality,'') AS nationality,
        IFNULL(pubhdrs.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article, 
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(pubhdrs.impactfactor,'') as impactfactor, IFNULL(pubhdrs.place,'') AS location
        FROM pubhdrs INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
        INNER JOIN categories ON categories.id = pubhdrs.categoryid
        INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid
        LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
        LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
        LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid
        /*LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid*/
        where pubdate BETWEEN fromdate and todate
        and pubhdrs.nationality IN (nationality)
        AND LOWER(categories.category) IN (categoryname COLLATE utf8mb4_unicode_ci)
        AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
           AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND pubhdrs.deleted = 0     
           GROUP by pubdtls.pubhdrid
           order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;

    ELSEIF type = 4 THEN /* Category criteria */

        SELECT pubhdrs.pubdate,pubdtls.pubhdrid,
        GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) as slno,
        /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
        GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,IFNULL(pubhdrs.title,'') AS title,IFNULL(pubhdrs.confname,'') as conference,IFNULL(pubhdrs.volume,'') as volume,IFNULL(pubhdrs.issue,'') as issue,IFNULL(pubhdrs.pp,'') as pages, IFNULL(pubhdrs.nationality,'') AS nationality,
        IFNULL(pubhdrs.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article,
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(pubhdrs.impactfactor,'') as impactfactor, IFNULL(pubhdrs.place,'') AS location
        FROM pubhdrs INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
        INNER JOIN categories ON categories.id = pubhdrs.categoryid
        INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid
        LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
        LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
        LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid
        /*LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid*/
        where categories.category IN (category COLLATE utf8mb4_unicode_ci)
        AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
           AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END

                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND pubhdrs.deleted = 0     
           GROUP by pubdtls.pubhdrid
           order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;

    ELSEIF type = 5 THEN /* Nationality criteria */

        SELECT pubhdrs.pubdate,pubdtls.pubhdrid,
        GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) as slno,
        /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
        GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,IFNULL(pubhdrs.title,'') AS title,IFNULL(pubhdrs.confname,'') as conference,IFNULL(pubhdrs.volume,'') as volume,IFNULL(pubhdrs.issue,'') as issue,IFNULL(pubhdrs.pp,'') as pages, IFNULL(pubhdrs.nationality,'') AS nationality,
        IFNULL(pubhdrs.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article,
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(pubhdrs.impactfactor,'') as impactfactor, IFNULL(pubhdrs.place,'') AS location
        FROM pubhdrs INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
        INNER JOIN categories ON categories.id = pubhdrs.categoryid
        INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid
        LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
        LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
        LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid
        /*LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid*/
        where pubhdrs.nationality IN (nationality)
        AND LOWER(categories.category) IN (categoryname COLLATE utf8mb4_unicode_ci)
        AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
           AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND pubhdrs.deleted = 0     
           GROUP by pubdtls.pubhdrid
           order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;

    ELSEIF type = 6 THEN  /* Category, Nationality criteria */

        SELECT pubhdrs.pubdate,pubdtls.pubhdrid,
        GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) as slno,
        /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
        GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,IFNULL(pubhdrs.title,'') AS title,IFNULL(pubhdrs.confname,'') as conference,IFNULL(pubhdrs.volume,'') as volume,IFNULL(pubhdrs.issue,'') as issue,IFNULL(pubhdrs.pp,'') as pages, IFNULL(pubhdrs.nationality,'') AS nationality,
        IFNULL(pubhdrs.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article,
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(pubhdrs.impactfactor,'') as impactfactor, IFNULL(pubhdrs.place,'') AS location
        FROM pubhdrs INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
        INNER JOIN categories ON categories.id = pubhdrs.categoryid
        INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid
        LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
        LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
        LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid
        /*LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid*/
        where categories.category IN (category COLLATE utf8mb4_unicode_ci)
        and pubhdrs.nationality IN (nationality)
        AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
           AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND pubhdrs.deleted = 0     
           GROUP by pubdtls.pubhdrid
           order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;

    ELSEIF type = 7 THEN  /* Date Category, Nationality criteria */

        SELECT pubhdrs.pubdate,pubdtls.pubhdrid,
        GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) as slno,
        /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
        GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,IFNULL(pubhdrs.title,'') AS title,IFNULL(pubhdrs.confname,'') as conference,IFNULL(pubhdrs.volume,'') as volume,IFNULL(pubhdrs.issue,'') as issue,IFNULL(pubhdrs.pp,'') as pages, IFNULL(pubhdrs.nationality,'') AS nationality,
        IFNULL(pubhdrs.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article,
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(pubhdrs.impactfactor,'') as impactfactor, IFNULL(pubhdrs.place,'') AS location
        FROM pubhdrs INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
        INNER JOIN categories ON categories.id = pubhdrs.categoryid
        INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid
        LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
        LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
        LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid
        /*LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid*/
        where pubdate BETWEEN fromdate and todate
        and categories.category IN (category COLLATE utf8mb4_unicode_ci)
        and pubhdrs.nationality IN (nationality)
        AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
           AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND pubhdrs.deleted = 0     
           GROUP by pubdtls.pubhdrid
           order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;
       
    END IF;
END IF;

IF rankingcopy = 1 AND type <> 8 THEN  /* ranking and author condition */
    
		IF ranking = '' THEN SET ranking = ','; END IF;

        WHILE ranking != '' DO
            SET element = SUBSTRING_INDEX(ranking, ',', 1);

            IF(element > 0) THEN
                INSERT INTO Temp_Rankings_Print VALUES(element);
            END IF;

            IF LOCATE(',', ranking) > 0 THEN
                SET ranking = SUBSTRING(ranking, LOCATE(',', ranking) + 1);
            ELSE
                SET ranking = '';
            END IF;
    	END WHILE;
        
        IF type = 0 THEN /* All search criteria */

          SELECT hdr.pubdate,dtls.pubhdrid,cat.category,
        GROUP_CONCAT(dtls.slno ORDER BY dtls.slno) as slno,  
        /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''),   2) ORDER BY dtls.slno)*/
        GROUP_CONCAT(CASE WHEN dtls.slno != 1 THEN concat(" ",dtls.fullname) ELSE dtls.fullname END ORDER BY dtls.slno) as authorname,IFNULL(hdr.title,'') AS title,IFNULL(hdr.confname,'') as conference,IFNULL(hdr.volume,'') as volume,IFNULL(hdr.issue,'') as issue,IFNULL(hdr.pp,'') as pages, IFNULL(hdr.nationality,'') AS nationality,IFNULL(hdr.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article,
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(hdr.impactfactor,'') as impactfactor, IFNULL(hdr.place,'') AS location
           FROM pubhdrs hdr
           INNER JOIN categories cat ON cat.id = hdr.categoryid
           LEFT OUTER JOIN articletypes art ON art.articleid = hdr.articletypeid 
           LEFT OUTER JOIN rankings rnk ON rnk.id = hdr.rankingid
           RIGHT OUTER JOIN Temp_Rankings_Print rank ON rnk.id = rank.rankingids
           LEFT OUTER JOIN broadareas brdarea ON brdarea.id = hdr.broadareaid
           /*LEFT OUTER JOIN impactfactors impact ON impact.id = hdr.impactfactorid*/
           INNER JOIN pubdtls dtls ON hdr.id = dtls.pubhdrid
           INNER JOIN authortypes authtype ON authtype.id = hdr.authortypeid
           WHERE LOWER(cat.category) IN (categoryname COLLATE utf8mb4_unicode_ci)
           AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
           AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN hdr.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN hdr.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND hdr.deleted = 0     
           GROUP by dtls.pubhdrid
           order by IFNULL(hdr.nationality,''),pubdate,pubhdrid;
           
    ELSEIF type = 1 THEN /* Date search criteria */

          SELECT pubhdrs.pubdate,pubdtls.pubhdrid,categories.category,
          GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) as slno,
          /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),'  ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
          GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,IFNULL(pubhdrs.title,'') AS title,IFNULL(pubhdrs.confname,'') as conference,IFNULL(pubhdrs.volume,'') AS volume,IFNULL(pubhdrs.issue,'') as issue,IFNULL(pubhdrs.pp,'') as pages, IFNULL(pubhdrs.nationality,'') AS nationality,
        IFNULL(pubhdrs.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article,
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(pubhdrs.impactfactor,'') as impactfactor, IFNULL(pubhdrs.place,'') AS location
           FROM pubhdrs INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
           INNER JOIN categories ON categories.id = pubhdrs.categoryid
           INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid
           LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
           LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
           RIGHT OUTER JOIN Temp_Rankings_Print rank ON rnk.id = rank.rankingids
           LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid
           /*LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid*/
           where pubdate BETWEEN fromdate and todate
           AND LOWER(categories.category) IN (categoryname COLLATE utf8mb4_unicode_ci)
           AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
           AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND pubhdrs.deleted = 0      
           GROUP by pubdtls.pubhdrid
           order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;     
           
      ELSEIF type = 2 THEN /* Category, Date criteria */

         SELECT pubhdrs.pubdate,pubdtls.pubhdrid,
         GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) as slno,
         /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
         GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,IFNULL(pubhdrs.title,'') AS title,IFNULL(pubhdrs.confname,'') as conference,IFNULL(pubhdrs.volume,'') as volume,IFNULL(pubhdrs.issue,'') as issue,IFNULL(pubhdrs.pp,'') as pages, IFNULL(pubhdrs.nationality,'') AS nationality,
        IFNULL(pubhdrs.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article,
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(pubhdrs.impactfactor,'') as impactfactor, IFNULL(pubhdrs.place,'') AS location
        FROM pubhdrs INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
        INNER JOIN categories ON categories.id = pubhdrs.categoryid
        INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid
        LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
        LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
         RIGHT OUTER JOIN Temp_Rankings_Print rank ON rnk.id = rank.rankingids
         LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid
         /*LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid*/
           where pubdate BETWEEN fromdate and todate
          and categories.category IN (category COLLATE utf8mb4_unicode_ci)
          AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
          AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND pubhdrs.deleted = 0     
           GROUP by pubdtls.pubhdrid
           order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;
           
     ELSEIF type = 3 THEN /* Nationality, Date criteria */

         SELECT pubhdrs.pubdate,pubdtls.pubhdrid,
         GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) as slno,
         /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
         GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,IFNULL(pubhdrs.title,'') AS title,IFNULL(pubhdrs.confname,'') as conference,IFNULL(pubhdrs.volume,'') as volume,IFNULL(pubhdrs.issue,'') as issue,IFNULL(pubhdrs.pp,'') as pages, IFNULL(pubhdrs.nationality,'') AS nationality,
        IFNULL(pubhdrs.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article, 
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(pubhdrs.impactfactor,'') as impactfactor, IFNULL(pubhdrs.place,'') AS location
        FROM pubhdrs INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
        INNER JOIN categories ON categories.id = pubhdrs.categoryid
        INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid
        LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
           LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
           RIGHT OUTER JOIN Temp_Rankings_Print rank ON rnk.id = rank.rankingids
           LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid
           /*LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid*/
           where pubdate BETWEEN fromdate and todate
           and pubhdrs.nationality IN (nationality)
           AND LOWER(categories.category) IN (categoryname COLLATE utf8mb4_unicode_ci)
           AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
           AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND pubhdrs.deleted = 0     
           GROUP by pubdtls.pubhdrid
           order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;
           
     ELSEIF type = 4 THEN /* Category criteria */

        SELECT pubhdrs.pubdate,pubdtls.pubhdrid,
        GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) as slno,
        /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
        GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,IFNULL(pubhdrs.title,'') AS title,IFNULL(pubhdrs.confname,'') as conference,IFNULL(pubhdrs.volume,'') as volume,IFNULL(pubhdrs.issue,'') as issue,IFNULL(pubhdrs.pp,'') as pages, IFNULL(pubhdrs.nationality,'') AS nationality,
        IFNULL(pubhdrs.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article,
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(pubhdrs.impactfactor,'') as impactfactor, IFNULL(pubhdrs.place,'') AS location
        FROM pubhdrs INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
        INNER JOIN categories ON categories.id = pubhdrs.categoryid
        INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid
        LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
           LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
           RIGHT OUTER JOIN Temp_Rankings_Print rank ON rnk.id = rank.rankingids
           LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid
           /*LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid*/
           where categories.category IN (category COLLATE utf8mb4_unicode_ci)
           AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
           AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND pubhdrs.deleted = 0     
           GROUP by pubdtls.pubhdrid
           order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;
           
    ELSEIF type = 5 THEN /* Nationality criteria */

        SELECT pubhdrs.pubdate,pubdtls.pubhdrid,
        GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) as slno,
        /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
       GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,IFNULL(pubhdrs.title,'') AS title,IFNULL(pubhdrs.confname,'') as conference,IFNULL(pubhdrs.volume,'') as volume,IFNULL(pubhdrs.issue,'') as issue,IFNULL(pubhdrs.pp,'') as pages, IFNULL(pubhdrs.nationality,'') AS nationality,
        IFNULL(pubhdrs.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article,
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(pubhdrs.impactfactor,'') as impactfactor, IFNULL(pubhdrs.place,'') AS location
        FROM pubhdrs INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
        INNER JOIN categories ON categories.id = pubhdrs.categoryid
        INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid
        LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
           LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
           RIGHT OUTER JOIN Temp_Rankings_Print rank ON rnk.id = rank.rankingids
           LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid
           /*LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid*/
           where pubhdrs.nationality IN (nationality)
           AND LOWER(categories.category) IN (categoryname COLLATE utf8mb4_unicode_ci)
           AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
           AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND pubhdrs.deleted = 0     
           GROUP by pubdtls.pubhdrid
           order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;

    ELSEIF type = 6 THEN  /* Category, Nationality criteria */

        SELECT pubhdrs.pubdate,pubdtls.pubhdrid,
        GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) as slno,
        /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
        GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,IFNULL(pubhdrs.title,'') AS title,IFNULL(pubhdrs.confname,'') as conference,IFNULL(pubhdrs.volume,'') as volume,IFNULL(pubhdrs.issue,'') as issue,IFNULL(pubhdrs.pp,'') as pages, IFNULL(pubhdrs.nationality,'') AS nationality,
        IFNULL(pubhdrs.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article,
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(impact.impactfactor,'') as impactfactor, IFNULL(pubhdrs.place,'') AS location
        FROM pubhdrs INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
        INNER JOIN categories ON categories.id = pubhdrs.categoryid
        INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid
        LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
           LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
           RIGHT OUTER JOIN Temp_Rankings_Print rank ON rnk.id = rank.rankingids
           LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid
           LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid
           where categories.category IN (category COLLATE utf8mb4_unicode_ci)
           and pubhdrs.nationality IN (nationality)
           AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
           AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND pubhdrs.deleted = 0     
           GROUP by pubdtls.pubhdrid
           order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;

    ELSEIF type = 7 THEN  /* Date Category, Nationality criteria */

        SELECT pubhdrs.pubdate,pubdtls.pubhdrid,
        GROUP_CONCAT(pubdtls.slno ORDER BY pubdtls.slno) as slno,
        /*GROUP_CONCAT(UCASE(LEFT(IFNULL(athrfirstname,''),1)),SUBSTRING(IFNULL(athrfirstname,''), 2),' ',UCASE(LEFT(IFNULL(athrmiddlename,''), 1)),SUBSTRING(IFNULL(athrmiddlename,''), 2), UCASE(LEFT(IFNULL(athrlastname,''), 1)),SUBSTRING(IFNULL(athrlastname,''), 2) ORDER BY pubdtls.slno)*/
        GROUP_CONCAT(CASE WHEN pubdtls.slno != 1 THEN concat(" ",pubdtls.fullname) ELSE pubdtls.fullname END ORDER BY pubdtls.slno) as authorname,IFNULL(pubhdrs.title,'') AS title,IFNULL(pubhdrs.confname,'') as conference,IFNULL(pubhdrs.volume,'') as volume,IFNULL(pubhdrs.issue,'') as issue,IFNULL(pubhdrs.pp,'') as pages, IFNULL(pubhdrs.nationality,'') AS nationality,
        IFNULL(pubhdrs.digitallibrary,'') AS Doi,IFNULL(art.article,'') AS article,
        IFNULL(rnk.ranking,'') as ranking, IFNULL(brdarea.broadarea,'') as broadarea,
        IFNULL(impact.impactfactor,'') as impactfactor, IFNULL(pubhdrs.place,'') AS location
        FROM pubhdrs INNER JOIN pubdtls ON pubhdrs.id = pubdtls.pubhdrid
        INNER JOIN categories ON categories.id = pubhdrs.categoryid
        INNER JOIN authortypes authtype ON authtype.id = pubhdrs.authortypeid
        LEFT OUTER JOIN articletypes art ON art.articleid = pubhdrs.articletypeid 
           LEFT OUTER JOIN rankings rnk ON rnk.id = pubhdrs.rankingid
           RIGHT OUTER JOIN Temp_Rankings_Print rank ON rnk.id = rank.rankingids
           LEFT OUTER JOIN broadareas brdarea ON brdarea.id = pubhdrs.broadareaid
           LEFT OUTER JOIN impactfactors impact ON impact.id = pubhdrs.impactfactorid
           where pubdate BETWEEN fromdate and todate
           and categories.category IN (category COLLATE utf8mb4_unicode_ci)
           and pubhdrs.nationality IN (nationality)
           AND CASE WHEN IFNULL(authortypeid,0) > 0 THEN authtype.id = IFNULL(authortypeid,0) ELSE 1=1 END
           AND	CASE WHEN IFNULL(title COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.title like concat('%',IFNULL(title COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
                AND	CASE WHEN IFNULL(conference COLLATE utf8mb4_unicode_ci,'') != '' THEN pubhdrs.confname like concat('%',IFNULL(conference COLLATE utf8mb4_unicode_ci,''),'%') ELSE 1=1 END
           AND pubhdrs.deleted = 0     
           GROUP by pubdtls.pubhdrid
           order by IFNULL(pubhdrs.nationality,''),pubdate,pubhdrid;     
           
       END IF;    
        
END IF;         

IF type = 8 THEN /* CALL GetAuthor */

 CALL GetAuthor(fname,mname,lname,subtype,fromdate,todate,category,nationality,categoryname,authortypeid,title,conference,ranking);  
 
END IF; 

DROP TEMPORARY TABLE IF EXISTS Temp_Rankings_Print;

    
	END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `articletypes`
--

CREATE TABLE `articletypes` (
  `articleid` int(11) NOT NULL,
  `article` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `journalconfernce` varchar(11) COLLATE utf8mb4_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `articletypes`
--

INSERT INTO `articletypes` (`articleid`, `article`, `journalconfernce`) VALUES
(1, 'Short', 'conference'),
(2, 'Long', 'conference'),
(3, 'Poster', 'conference');

-- --------------------------------------------------------

--
-- Table structure for table `authortypes`
--

CREATE TABLE `authortypes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `authortype` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `authortypes`
--

INSERT INTO `authortypes` (`id`, `authortype`, `created_at`, `updated_at`) VALUES
(1, 'Faculty', NULL, NULL),
(2, 'Student', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `broadareas`
--

CREATE TABLE `broadareas` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `broadarea` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `broadareas`
--

INSERT INTO `broadareas` (`id`, `broadarea`, `created_at`, `updated_at`) VALUES
(9, 'Networks', '2020-07-14 23:46:23', '2020-07-14 23:46:23'),
(17, 'Data Science', NULL, NULL),
(18, 'Systems', NULL, NULL),
(19, 'Theory', '2020-10-23 04:29:48', '2020-10-23 04:29:48');

-- --------------------------------------------------------

--
-- Table structure for table `campuses`
--

CREATE TABLE `campuses` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `campus` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `defaultemail` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `campuses`
--

INSERT INTO `campuses` (`id`, `campus`, `defaultemail`, `created_at`, `updated_at`) VALUES
(1, 'Pilani', 'pilani.bits-pilani.ac.in', NULL, NULL),
(2, 'Goa', 'goa.bits-pilani.ac.in', NULL, NULL),
(3, 'Hyderabad', 'hyderabad.bits-pilani.ac.in', NULL, NULL),
(4, 'Dubai', 'dubai.bits-pilani.ac.in', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `category` varchar(25) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `category`, `created_at`, `updated_at`) VALUES
(7, 'Journal', NULL, NULL),
(8, 'Conference/Workshop', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `campusid` bigint(20) UNSIGNED NOT NULL,
  `department` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `departments`
--

INSERT INTO `departments` (`id`, `campusid`, `department`, `created_at`, `updated_at`) VALUES
(1, 2, 'Department of Biological Sciences', NULL, NULL),
(2, 2, 'Department of Chemical Engineering', NULL, NULL),
(3, 2, 'Department of Chemistry', NULL, NULL),
(4, 2, 'Department of Computer Science & Information Systems', NULL, NULL),
(5, 2, 'Department of Economics', NULL, NULL),
(6, 2, 'Department of Electrical and Electronics Engineering', NULL, NULL),
(7, 2, 'Department of Humanities and Social Sciences', NULL, NULL),
(8, 2, 'Department of Mathematics', NULL, NULL),
(9, 2, 'Department of Mechanical Engineering', NULL, NULL),
(10, 2, 'Department of Physics', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `connection` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `queue` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `exception` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `impactfactors`
--

CREATE TABLE `impactfactors` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `impactfactor` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `impactfactors`
--

INSERT INTO `impactfactors` (`id`, `impactfactor`, `created_at`, `updated_at`) VALUES
(5, 'Others', '2020-07-14 23:46:34', '2020-07-14 23:46:34'),
(12, '2.76', '2020-09-15 04:30:41', '2020-09-15 04:30:41'),
(13, '1.46', '2020-09-15 04:30:49', '2020-09-15 04:30:49'),
(14, '0.7', '2020-09-15 04:31:18', '2020-09-15 04:31:18'),
(15, '2.41', '2020-09-15 04:31:31', '2020-09-15 04:31:31'),
(16, '1.2', '2020-09-15 04:34:45', '2020-09-15 04:34:45'),
(17, '5.23', '2020-09-15 23:46:06', '2020-09-15 23:46:06');

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(4, '2014_10_12_100000_create_password_resets_table', 1),
(5, '2019_08_19_000000_create_failed_jobs_table', 1),
(6, '2020_10_21_092327_create_campuses_table', 1),
(7, '2020_10_21_092809_create_departments_table', 1),
(9, '2020_10_22_051814_create_userregistrations_table', 2),
(45, '2014_10_12_000000_create_users_table', 1),
(46, '2014_10_12_100000_create_password_resets_table', 1),
(48, '2020_05_26_043534_create-category-table', 1),
(49, '2020_05_26_043652_create-author-table', 1),
(50, '2020_05_26_054203_create-ranking-table', 1),
(51, '2020_05_26_054226_create-broadarea-table', 1),
(52, '2020_05_26_054251_create-impactfactor-table', 1),
(84, '2019_08_19_000000_create_failed_jobs_table', 2),
(97, '2020_05_26_084403_create-category-table', 3),
(98, '2020_05_26_084417_create-authortype-table', 3),
(99, '2020_05_26_084425_create-ranking-table', 3),
(100, '2020_05_26_084433_create-broadarea-table', 3),
(101, '2020_05_26_084442_create-impactfactor-table', 3),
(102, '2020_05_26_085916_create-testmain-table', 3),
(103, '2020_05_26_100658_create-testprimary-table', 4),
(104, '2020_05_26_100741_create-testforeign-table', 4),
(115, '2020_05_26_102228_create-product-table', 5),
(116, '2020_05_26_102349_create-productprice-table', 5),
(117, '2020_05_26_104815_create-category-table', 6),
(118, '2020_05_26_104933_create-authortype-table', 6),
(119, '2020_05_26_105033_create-ranking-table', 6),
(120, '2020_05_26_105125_create-broadarea-table', 6),
(121, '2020_05_26_105229_create-impactfactor-table', 7),
(122, '2020_05_26_105432_create-pubhdr-table', 7),
(124, '2020_05_26_110308_create-pubdtl-table', 8);

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `productprices`
--

CREATE TABLE `productprices` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `product_id` bigint(20) UNSIGNED NOT NULL,
  `price` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pubdtls`
--

CREATE TABLE `pubdtls` (
  `slno` bigint(20) NOT NULL,
  `pubhdrid` bigint(20) UNSIGNED NOT NULL,
  `athrfirstname` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `athrmiddlename` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `athrlastname` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fullname` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `inhouseflag` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `pubdtls`
--

INSERT INTO `pubdtls` (`slno`, `pubhdrid`, `athrfirstname`, `athrmiddlename`, `athrlastname`, `fullname`, `inhouseflag`, `created_at`, `updated_at`) VALUES
(1, 1, 'Abhiraj', NULL, 'Hinge', 'Abhiraj Hinge', 0, NULL, NULL),
(1, 2, 'Rakesh', 'Ranjan', 'Swain', 'Rakesh Ranjan Swain', 0, NULL, NULL),
(1, 3, 'Sujith', NULL, 'Thomas', 'Sujith Thomas', 0, NULL, NULL),
(1, 4, 'Kushagra', NULL, 'Mahajan', 'Kushagra Mahajan', 0, NULL, NULL),
(1, 5, 'Sujith', NULL, 'Thomas', 'Sujith Thomas', 0, NULL, NULL),
(1, 6, 'Sujith', NULL, 'Thomas', 'Sujith Thomas', 0, NULL, NULL),
(1, 7, 'Soundarya', NULL, 'Krishnan', 'Soundarya Krishnan', 0, NULL, NULL),
(1, 8, 'Sharan', NULL, 'Yalburgi', 'Sharan Yalburgi', 0, NULL, NULL),
(1, 9, 'Soundarya', NULL, 'Krishnan', 'Soundarya Krishnan', 0, NULL, NULL),
(1, 10, 'Raj', 'K', 'Jaiswal', 'Raj K Jaiswal', 0, NULL, NULL),
(1, 11, 'S', NULL, 'Giridher', 'S Giridher', 0, NULL, NULL),
(1, 12, 'K', NULL, 'Phokela', 'K Phokela', 0, NULL, NULL),
(1, 13, 'P', NULL, 'Sharma', 'P Sharma', 0, NULL, NULL),
(1, 14, 'Dheryta', NULL, 'Jaisinghani', 'Dheryta Jaisinghani', 0, NULL, NULL),
(1, 15, 'Sharan', 'Ranjit', 'S', 'Sharan Ranjit S', 0, NULL, NULL),
(1, 16, 'Aman', 'Kumar', 'Singh', 'Aman Kumar Singh', 0, NULL, NULL),
(1, 17, 'Rachit', NULL, 'Rastogi', 'Rachit Rastogi', 0, NULL, NULL),
(1, 18, 'Raj', 'K', 'Jaiswal', 'Raj K Jaiswal', 0, NULL, NULL),
(1, 19, 'Zaiba', 'Hasan', 'Khan', 'Zaiba Hasan Khan', 0, NULL, NULL),
(1, 20, 'Bhavye', NULL, 'Jain', 'Bhavye Jain', 0, NULL, NULL),
(1, 21, 'Rajaswa', NULL, 'Patil', 'Rajaswa Patil', 0, NULL, NULL),
(1, 22, 'Swati', NULL, 'Agarwal', 'Swati Agarwal', 0, NULL, NULL),
(1, 23, 'Shourya', NULL, 'Shukla', 'Shourya Shukla', 0, NULL, NULL),
(1, 24, 'Ashwin', NULL, 'Srinivasan', 'Ashwin Srinivasan', 0, NULL, NULL),
(1, 25, 'Tirtharaj', NULL, 'Dash', 'Tirtharaj Dash', 0, NULL, NULL),
(1, 26, 'Mouli', NULL, 'Rastogi', 'Mouli Rastogi', 0, NULL, NULL),
(1, 27, 'Snehanshu', NULL, 'Saha', 'Snehanshu Saha', 0, NULL, NULL),
(1, 28, 'Rahul', NULL, 'Yedida', 'Rahul Yedida', 0, NULL, NULL),
(1, 29, 'Harikrishnan', 'Nellippallil', 'Balakrishnan', 'Harikrishnan Nellippallil Balakrishnan', 0, NULL, NULL),
(1, 30, 'Suryoday', NULL, 'Basak', 'Suryoday Basak', 0, NULL, NULL),
(1, 31, 'Snehanshu', NULL, 'Saha', 'Snehanshu Saha', 0, NULL, NULL),
(1, 32, 'Shailesh', NULL, 'Sridhar', 'Shailesh Sridhar', 0, NULL, NULL),
(1, 33, 'R.', NULL, 'Reddy', 'R. Reddy', 0, NULL, NULL),
(1, 34, 'Snehanshu', NULL, 'Saha', 'Snehanshu Saha', 0, NULL, NULL),
(1, 35, 'Shashank', 'Sanjay', 'Bhat', 'Shashank Sanjay Bhat', 0, NULL, NULL),
(2, 1, 'Pranav', NULL, 'Garg', 'Pranav Garg', 0, NULL, NULL),
(2, 2, 'Tirtharaj', NULL, 'Dash', 'Tirtharaj Dash', 0, NULL, NULL),
(2, 3, 'Narayanan', NULL, 'Srinivasan', 'Narayanan Srinivasan', 0, NULL, NULL),
(2, 4, 'Monika', NULL, 'Sharma', 'Monika Sharma', 0, NULL, NULL),
(2, 5, 'Aditya', NULL, 'Kapoor', 'Aditya Kapoor', 0, NULL, NULL),
(2, 6, 'Narayanan', NULL, 'Srinivasan', 'Narayanan Srinivasan', 0, NULL, NULL),
(2, 7, 'Rishab', NULL, 'Khincha', 'Rishab Khincha', 0, NULL, NULL),
(2, 8, 'Tirtharaj', NULL, 'Dash', 'Tirtharaj Dash', 0, NULL, NULL),
(2, 9, 'Rishab', NULL, 'Khincha', 'Rishab Khincha', 0, NULL, NULL),
(2, 11, 'A', NULL, 'Gupta', 'A Gupta', 0, NULL, NULL),
(2, 12, 'Vinayak', NULL, 'Naik', 'Vinayak Naik', 0, NULL, NULL),
(2, 13, 'D', NULL, 'Gosain', 'D Gosain', 0, NULL, NULL),
(2, 14, 'Naman', NULL, 'Gupta', 'Naman Gupta', 0, NULL, NULL),
(2, 15, 'Raj', 'K', 'Jaiswal', 'Raj K Jaiswal', 0, NULL, NULL),
(2, 16, 'Raj', 'K', 'Jaiswal', 'Raj K Jaiswal', 0, NULL, NULL),
(2, 17, 'Ritika', NULL, 'Jaiswal', 'Ritika Jaiswal', 0, NULL, NULL),
(2, 19, 'Swati', NULL, 'Agarwal', 'Swati Agarwal', 0, NULL, NULL),
(2, 20, 'Kaustubh', NULL, 'Trivedi', 'Kaustubh Trivedi', 0, NULL, NULL),
(2, 21, 'Somesh', NULL, 'Singh', 'Somesh Singh', 0, NULL, NULL),
(2, 22, 'Rahul', NULL, 'Thakur', 'Rahul Thakur', 0, NULL, NULL),
(2, 23, 'Rahul', NULL, 'Thakur', 'Rahul Thakur', 0, NULL, NULL),
(2, 24, 'Lovekesh', NULL, 'Vig', 'Lovekesh Vig', 0, NULL, NULL),
(2, 25, 'Ashwin', NULL, 'Srinivasan', 'Ashwin Srinivasan', 0, NULL, NULL),
(2, 26, 'Syed', NULL, 'Afshan Ali', 'Syed Afshan Ali', 0, NULL, NULL),
(2, 27, 'Nithin', NULL, 'Nagaraj', 'Nithin Nagaraj', 0, NULL, NULL),
(2, 28, 'Snehanshu', NULL, 'Saha', 'Snehanshu Saha', 0, NULL, NULL),
(2, 29, 'Aditi', NULL, 'Kathpalia', 'Aditi Kathpalia', 0, NULL, NULL),
(2, 30, 'Snehanshu', NULL, 'Saha', 'Snehanshu Saha', 0, NULL, NULL),
(2, 31, 'Tejas', NULL, 'Prashanth', 'Tejas Prashanth', 0, NULL, NULL),
(2, 32, 'Snehanshu', NULL, 'Saha', 'Snehanshu Saha', 0, NULL, NULL),
(2, 33, 'Snehanshu', NULL, 'Saha', 'Snehanshu Saha', 0, NULL, NULL),
(2, 34, 'Nithin', NULL, 'Nagaraj', 'Nithin Nagaraj', 0, NULL, NULL),
(2, 35, 'Prabu', NULL, 'T', 'Prabu T', 0, NULL, NULL),
(3, 1, 'Neena', NULL, 'Goveas', 'Neena Goveas', 0, NULL, NULL),
(3, 2, 'Pabitra', 'Mohan', 'Khilar', 'Pabitra Mohan Khilar', 0, NULL, NULL),
(3, 4, 'Lovekesh', NULL, 'Vig', 'Lovekesh Vig', 0, NULL, NULL),
(3, 5, 'Narayanan', NULL, 'Srinivasan', 'Narayanan Srinivasan', 0, NULL, NULL),
(3, 7, 'Lovekesh', NULL, 'Vig', 'Lovekesh Vig', 0, NULL, NULL),
(3, 8, 'Ramya', NULL, 'Hebbalaguppe', 'Ramya Hebbalaguppe', 0, NULL, NULL),
(3, 9, 'Lovekesh', NULL, 'Vig', 'Lovekesh Vig', 0, NULL, NULL),
(3, 11, 'S', NULL, 'Jaiswal', 'S Jaiswal', 0, NULL, NULL),
(3, 13, 'H', NULL, 'Sagar', 'H Sagar', 0, NULL, NULL),
(3, 14, 'Mukulika', NULL, 'Maity', 'Mukulika Maity', 0, NULL, NULL),
(3, 17, 'Raj', 'K', 'Jaiswal', 'Raj K Jaiswal', 0, NULL, NULL),
(3, 19, 'Atul', NULL, 'Rai', 'Atul Rai', 0, NULL, NULL),
(3, 20, 'Swati', NULL, 'Agarwal', 'Swati Agarwal', 0, NULL, NULL),
(3, 21, 'Swati', NULL, 'Agarwal', 'Swati Agarwal', 0, NULL, NULL),
(3, 22, 'Utkarsh', NULL, 'Yadav', 'Utkarsh Yadav', 0, NULL, NULL),
(3, 23, 'Swati', NULL, 'Agarwal', 'Swati Agarwal', 0, NULL, NULL),
(3, 24, 'Gautam', NULL, 'Shroff', 'Gautam Shroff', 0, NULL, NULL),
(3, 25, 'Lovekesh', NULL, 'Vig', 'Lovekesh Vig', 0, NULL, NULL),
(3, 26, 'Mrinal', NULL, 'Rawat', 'Mrinal Rawat', 0, NULL, NULL),
(3, 27, 'Archana', NULL, 'Mathur', 'Archana Mathur', 0, NULL, NULL),
(3, 28, 'Tejas', NULL, 'Prashanth', 'Tejas Prashanth', 0, NULL, NULL),
(3, 29, 'Snehanshu', NULL, 'Saha', 'Snehanshu Saha', 0, NULL, NULL),
(3, 30, 'Archana', NULL, 'Mathur', 'Archana Mathur', 0, NULL, NULL),
(3, 31, 'Suraj', NULL, 'Aralihalli', 'Suraj Aralihalli', 0, NULL, NULL),
(3, 32, 'Azhar', NULL, 'Shaikh', 'Azhar Shaikh', 0, NULL, NULL),
(3, 33, 'S.', NULL, 'Roy Dey', 'S. Roy Dey', 0, NULL, NULL),
(3, 34, 'Archana', NULL, 'Mathur', 'Archana Mathur', 0, NULL, NULL),
(3, 35, 'Snehanshu', NULL, 'Saha', 'Snehanshu Saha', 0, NULL, NULL),
(4, 4, 'Rishab', NULL, 'Khincha', 'Rishab Khincha', 0, NULL, NULL),
(4, 7, 'Tirtharaj', NULL, 'Dash', 'Tirtharaj Dash', 0, NULL, NULL),
(4, 8, 'Srinidhi', NULL, 'Hegde', 'Srinidhi Hegde', 0, NULL, NULL),
(4, 9, 'Tirtharaj', NULL, 'Dash', 'Tirtharaj Dash', 0, NULL, NULL),
(4, 11, 'Vinayak', NULL, 'Naik', 'Vinayak Naik', 0, NULL, NULL),
(4, 13, 'C', NULL, 'Kumar', 'C Kumar', 0, NULL, NULL),
(4, 14, 'Vinayak', NULL, 'Naik', 'Vinayak Naik', 0, NULL, NULL),
(4, 19, 'Mounil', 'Binal', 'Memaya', 'Mounil Binal Memaya', 0, NULL, NULL),
(4, 20, 'Rahul', NULL, 'Thakur', 'Rahul Thakur', 0, NULL, NULL),
(4, 22, 'Hemant', NULL, 'Rathore', 'Hemant Rathore', 0, NULL, NULL),
(4, 26, 'Lovekesh', NULL, 'Vig', 'Lovekesh Vig', 0, NULL, NULL),
(4, 27, 'Rahul', NULL, 'Yedida', 'Rahul Yedida', 0, NULL, NULL),
(4, 29, 'Nithin', NULL, 'Nagaraj', 'Nithin Nagaraj', 0, NULL, NULL),
(4, 30, 'Kakoli', NULL, 'Bora', 'Kakoli Bora', 0, NULL, NULL),
(4, 31, 'Sumedh', NULL, 'Basarkod', 'Sumedh Basarkod', 0, NULL, NULL),
(4, 32, 'Rahul', NULL, 'Yedida', 'Rahul Yedida', 0, NULL, NULL),
(4, 33, 'V.', NULL, 'Raychoudhury', 'V. Raychoudhury', 0, NULL, NULL),
(4, 34, 'Rahul', NULL, 'Yedida', 'Rahul Yedida', 0, NULL, NULL),
(5, 4, 'Soundarya', NULL, 'Krishnan', 'Soundarya Krishnan', 0, NULL, NULL),
(5, 7, 'Ashwin', NULL, 'Srinivasan', 'Ashwin Srinivasan', 0, NULL, NULL),
(5, 8, 'Ashwin', NULL, 'Srinivasan', 'Ashwin Srinivasan', 0, NULL, NULL),
(5, 9, 'Ashwin', NULL, 'Srinivasan', 'Ashwin Srinivasan', 0, NULL, NULL),
(5, 13, 'A', NULL, 'Dogra', 'A Dogra', 0, NULL, NULL),
(5, 19, 'Sandhya', NULL, 'Mehrotra', 'Sandhya Mehrotra', 0, NULL, NULL),
(5, 26, 'Puneet', NULL, 'Agarwal', 'Puneet Agarwal', 0, NULL, NULL),
(5, 27, 'Sneha', 'H', 'R', 'Sneha H R', 0, NULL, NULL),
(5, 30, 'Simran', NULL, 'Makhija', 'Simran Makhija', 0, NULL, NULL),
(5, 31, 'T.S.B.', NULL, 'Sudarshan', 'T.S.B. Sudarshan', 0, NULL, NULL),
(5, 32, 'Sriparna', NULL, 'Saha', 'Sriparna Saha', 0, NULL, NULL),
(6, 4, 'Adithya', NULL, 'Niranjan', 'Adithya Niranjan', 0, NULL, NULL),
(6, 13, 'Vinayak', NULL, 'Naik', 'Vinayak Naik', 0, NULL, NULL),
(6, 19, 'Rajesh', NULL, 'Mehrotra', 'Rajesh Mehrotra', 0, NULL, NULL),
(6, 26, 'Gautam', NULL, 'Shroff', 'Gautam Shroff', 0, NULL, NULL),
(6, 30, 'Margarita', NULL, 'Safonova', 'Margarita Safonova', 0, NULL, NULL),
(6, 31, 'Soma', 'S', 'Dhavala', 'Soma S Dhavala', 0, NULL, NULL),
(7, 4, 'Tirtharaj', NULL, 'Dash', 'Tirtharaj Dash', 0, NULL, NULL),
(7, 13, 'H', NULL, 'Acharya', 'H Acharya', 0, NULL, NULL),
(7, 26, 'Ashwin', NULL, 'Srinivasan', 'Ashwin Srinivasan', 0, NULL, NULL),
(7, 30, 'Surbhi', NULL, 'Agrawal', 'Surbhi Agrawal', 0, NULL, NULL),
(8, 4, 'Ashwin', NULL, 'Srinivasan', 'Ashwin Srinivasan', 0, NULL, NULL),
(8, 13, 'S', NULL, 'Chakravarty', 'S Chakravarty', 0, NULL, NULL),
(9, 4, 'Gautam', NULL, 'Shroff', 'Gautam Shroff', 0, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `pubhdrs`
--

CREATE TABLE `pubhdrs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `categoryid` bigint(20) UNSIGNED DEFAULT NULL,
  `authortypeid` bigint(20) UNSIGNED DEFAULT NULL,
  `articletypeid` int(11) DEFAULT NULL,
  `nationality` int(11) DEFAULT NULL,
  `pubdate` date NOT NULL,
  `title` varchar(250) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `confname` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `place` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `rankingid` bigint(20) UNSIGNED DEFAULT NULL,
  `broadareaid` bigint(20) UNSIGNED DEFAULT NULL,
  `impactfactor` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `volume` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issue` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pp` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `userid` bigint(20) UNSIGNED NOT NULL,
  `publisher` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `note` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deleted` tinyint(1) NOT NULL,
  `digitallibrary` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bibtexfile` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `pubhdrs`
--

INSERT INTO `pubhdrs` (`id`, `categoryid`, `authortypeid`, `articletypeid`, `nationality`, `pubdate`, `title`, `confname`, `place`, `rankingid`, `broadareaid`, `impactfactor`, `description`, `volume`, `issue`, `pp`, `userid`, `publisher`, `note`, `deleted`, `digitallibrary`, `bibtexfile`, `created_at`, `updated_at`) VALUES
(1, 8, 1, 1, 2, '2020-01-01', 'Image Processing for UAV Using Deep Convolutional Encoder–Decoder Networks with Symmetric Skip Connections on a System on Chip (SoC)', 'International Conference on Intelligent Computing and Smart Communication 2019', 'Springer, Singapore', NULL, 9, NULL, NULL, NULL, NULL, '1009-1015', 10, NULL, NULL, 0, 'ISBN 978-981-15-0633-8', '', '2020-12-20 21:05:44', '2020-12-20 21:05:44'),
(2, 7, 1, NULL, 2, '2020-01-21', 'Lightweight approach to automated fault diagnosis in WSNs', 'IET Networks', 'UK', 330, 9, NULL, NULL, NULL, NULL, NULL, 14, NULL, NULL, 0, '10.1049/iet-net.2019.0117', '', '2020-12-21 19:37:22', '2020-12-21 19:37:22'),
(3, 8, 1, 1, 2, '2020-07-29', 'Better learning of partially diagnostic features leads to less unidimensional categorization in supervised category learning', 'Proceedings of the 42nd Annual Conference of the Cognitive Science Society (pp. 3444--3450). Cognitive Science Society', 'Toronto, Canada', 332, 17, NULL, NULL, NULL, NULL, '3444--3450', 17, NULL, NULL, 1, NULL, '', '2020-12-21 19:39:43', '2020-12-21 19:52:26'),
(4, 8, 2, 2, 2, '2020-11-04', 'CovidDiagnosis: Deep Diagnosis of COVID-19 Patients Using Chest X-Rays', 'MICCAI-International Workshop on Thoracic Image Analysis', 'Lima, Peru', 248, 17, NULL, NULL, NULL, NULL, '61-73', 14, NULL, NULL, 0, 'https://doi.org/10.1007/978-3-030-62469-9_6', '', '2020-12-21 19:46:21', '2020-12-21 20:47:43'),
(5, 8, 1, 3, 2, '2020-06-29', 'Effect of a colour-based descriptor and stimuli presentation mode in unsupervised categorization', 'Proceedings of the 42nd Annual Conference of the Cognitive Science Society (p. 3531)', 'Toronto, Canada.', 332, 17, NULL, NULL, NULL, NULL, '3531', 17, NULL, NULL, 0, NULL, '', '2020-12-21 19:51:00', '2020-12-21 19:51:00'),
(6, 8, 1, 1, 2, '2020-07-29', 'Better learning of partially diagnostic features leads to less unidimensional categorization in supervised category learning', 'Proceedings of the 42nd Annual Conference of the Cognitive Science Society (pp. 3444--3450)', 'Toronto, Canada', 332, 17, NULL, NULL, NULL, NULL, '3444--3450', 17, NULL, NULL, 0, NULL, '', '2020-12-21 19:55:14', '2020-12-21 19:55:14'),
(7, 8, 2, 2, 2, '2020-10-02', 'A Case Study of Transfer of Lesion-Knowledge', 'MICCAI-International Workshop on Medical Image Learning with Less Labels and Imperfect Data', 'Lima, Peru', NULL, 17, NULL, NULL, NULL, NULL, '138-145', 14, NULL, NULL, 1, 'https://doi.org/10.1007/978-3-030-61166-8_15', '', '2020-12-21 20:25:48', '2020-12-21 20:49:19'),
(8, 8, 2, NULL, 2, '2020-10-02', 'An Empirical Study of Iterative Knowledge Distillation for Neural Network Compression', 'European Symposium on Artificial Neural Networks, Computational Intelligence and Machine Learning', 'Bruges, Belgium', 326, 17, NULL, NULL, NULL, NULL, '217-222', 14, NULL, NULL, 0, 'ISBN 978-2-87587-074-2', '', '2020-12-21 20:33:41', '2020-12-21 20:33:41'),
(9, 8, 2, 2, 2, '2020-10-02', 'A Case Study of Transfer of Lesion-Knowledge', 'MICCAI-International Workshop on Medical Image Learning with Less Labels and Imperfect Data', 'Lima, Peru', NULL, 17, NULL, NULL, NULL, NULL, '138-145', 14, NULL, NULL, 0, 'https://doi.org/10.1007/978-3-030-61166-8_15', '', '2020-12-21 20:37:23', '2020-12-21 20:37:23'),
(10, 7, 1, NULL, 2, '2020-05-01', 'Position-based routing protocol using Kalman filter as a prediction module for vehicular ad hoc networks', 'Computers & Electrical Engineering', 'NA', 328, 9, '2.6', NULL, '83', '106599', NULL, 19, NULL, NULL, 1, 'https://doi.org/10.1016/j.compeleceng.2020.106599', '', '2020-12-21 23:32:59', '2020-12-22 20:07:31'),
(11, 8, 1, 1, 2, '2020-01-07', 'Predicting Human Response in Feature Binding Experiment Using EEG Data', 'Networked Healthcare Technology (NetHealth\'20)', 'India', 328, 9, NULL, NULL, NULL, NULL, NULL, 8, NULL, NULL, 0, NULL, '', '2020-12-21 23:54:50', '2020-12-21 23:54:50'),
(12, 8, 1, 1, 2, '2020-01-07', 'Use of Smartphone\'s Headset Microphone to Estimate the Rate of Respiration', 'Networked Healthcare Technology (NetHealth\'20)', 'India', 328, 9, NULL, NULL, NULL, NULL, NULL, 8, NULL, NULL, 0, NULL, '', '2020-12-21 23:56:06', '2020-12-21 23:56:06'),
(13, 8, 1, 2, 2, '2020-07-14', 'SiegeBreaker: An SDN Based Practical Decoy Routing System', 'Privacy Enhancing Technologies Symposium', 'Canada', 326, 9, NULL, NULL, NULL, NULL, NULL, 8, NULL, NULL, 0, NULL, '', '2020-12-21 23:59:22', '2020-12-21 23:59:22'),
(14, 8, 1, 2, 2, '2020-12-10', 'Adaptive ViFi: A Dynamic Protocol for IoT Nodes in Challenged WiFi Network Conditions', 'International Conference on Mobile Ad-Hoc and Smart Systems', 'India', 326, 9, NULL, NULL, NULL, NULL, NULL, 8, NULL, NULL, 0, NULL, '', '2020-12-22 00:01:00', '2020-12-22 00:01:00'),
(15, 8, 2, 2, 2, '2020-02-15', 'Single Image Intrinsic Decomposition Using Transfer Learning', '12th International Conference on Machine Learning and Computing', 'China', 248, 17, NULL, NULL, NULL, NULL, '418-425', 19, NULL, NULL, 0, NULL, '', '2020-12-22 19:52:10', '2020-12-22 19:52:10'),
(16, 8, 2, 2, 2, '2020-02-18', 'DDoSify: Server Workload Migration During DDOS Attack In NFV', '9th International Conference on Software and Computer Applications', 'Malaysia', 248, 9, NULL, NULL, NULL, NULL, '364-369', 19, NULL, NULL, 0, NULL, '', '2020-12-22 19:55:08', '2020-12-22 19:55:08'),
(17, 8, 2, 2, 2, '2020-08-14', 'Renewable Energy Firm’s Performance Analysis Using Machine Learning Approach', 'Procedia Computer Science, Elsevier', 'Belgium', 328, 17, NULL, NULL, NULL, NULL, '500-507', 19, NULL, NULL, 0, NULL, '', '2020-12-22 19:58:11', '2020-12-22 20:05:21'),
(18, 7, 1, NULL, 2, '2020-05-01', 'Position-based routing protocol using Kalman filter as a prediction module for vehicular ad hoc networks', 'Computers & Electrical Engineering', 'NA', 328, 9, '2.6', NULL, '83', NULL, '106599', 19, NULL, NULL, 0, NULL, '', '2020-12-22 20:10:32', '2020-12-22 20:10:32'),
(19, 7, 1, NULL, 2, '2020-12-08', 'Co-expression Network Analysis of Protein Phosphatase 2A (PP2A) Genes with Stress-Responsive Genes in Arabidopsis thaliana Reveals 13 Key Regulators', 'Scientific Reports, Nature Publishing Group', '-', 329, NULL, '4.576', NULL, '10', NULL, NULL, 23, NULL, NULL, 0, 'https://dx.doi.org/10.1038%2Fs41598-020-77746-z', '', '2020-12-29 00:27:33', '2020-12-29 00:27:33'),
(20, 8, 1, 2, 2, '2020-12-25', 'MeshSOS: An IoT Based Emergency Response System', 'In 54th The Hawaii International Conference on System Sciences', 'Hawaii', 332, 18, NULL, NULL, NULL, NULL, NULL, 23, NULL, NULL, 0, NULL, '', '2020-12-29 00:30:25', '2020-12-29 00:30:25'),
(21, 8, 1, 2, 2, '2020-05-08', 'BPGC at SemEval-2020 Task 11: Propaganda Detection in News Articles with Multi-Granularity Knowledge Sharing and Linguistic Features based Ensemble Learning', '14th International Workshop on Semantic Evaluation, Co-located with 28th International Conference on Computational Linguistics (COLING)', 'Barcelona, Spain', 332, 17, NULL, NULL, NULL, NULL, NULL, 23, NULL, NULL, 0, NULL, '', '2020-12-29 00:33:28', '2020-12-29 00:33:28'),
(22, 8, 1, 2, 2, '2020-05-20', 'Socio-Cellular Network: A Novel Social Assisted Cellular Communication Paradigm', 'The 91st Vehicular Technology Conference: VTC2020-Spring', 'Antwerp, Belgium', 326, 9, NULL, NULL, NULL, NULL, NULL, 23, NULL, NULL, 0, 'https://ieeexplore.ieee.org/document/9129642', '', '2020-12-29 00:38:10', '2020-12-29 00:38:10'),
(23, 8, 1, 2, 2, '2020-12-25', 'Distributed Vehicular Dynamic Spectrum Access for Platooning Environments.', 'IEEE 92md Vehicular Technology Conference VTC Spring', 'Helsinki, Finland', 326, 9, NULL, NULL, NULL, NULL, NULL, 23, NULL, NULL, 0, NULL, '', '2020-12-29 00:39:44', '2020-12-29 00:39:44'),
(24, 7, 1, NULL, NULL, '2020-01-31', 'Constructing generative logical models for optimisation problems using domain knowledge', NULL, '-', 332, 17, NULL, NULL, NULL, NULL, '1371-1392', 9, NULL, NULL, 0, NULL, '', '2020-12-30 01:48:01', '2020-12-30 01:49:50'),
(25, 7, 1, NULL, NULL, '2020-01-01', 'Incorporating Symbolic Domain Knowledge into Graph Neural Networks', 'CoRR 2020', '-', NULL, 17, NULL, NULL, NULL, NULL, NULL, 9, NULL, NULL, 0, NULL, '', '2020-12-30 01:56:53', '2020-12-30 01:56:53'),
(26, 8, 1, 2, 2, '2020-01-01', 'Information Extraction from Document Images via FCA based Template Detection and Knowledge Graph Rule Induction', '2020 IEEE/CVF Conference on Computer Vision and Pattern Recognition, CVPR Workshops 2020', 'Seattle, WA, USA', 332, 17, NULL, NULL, NULL, NULL, '2377-2385', 9, NULL, NULL, 0, NULL, '', '2020-12-30 02:01:46', '2020-12-30 02:01:46'),
(27, 7, 1, NULL, NULL, '2020-11-09', 'Springer - Evolution of Novel Activation Functions in Neural\r\nNetwork Training for Astronomy Data: Habitability Classification of Exoplanets', 'EPJ Special Topics', 'Germany', NULL, NULL, '1.8', NULL, '229', NULL, '2629–2738', 7, NULL, NULL, 0, '10.1140/epjst/e2020-000098-9', '', '2021-01-27 01:28:40', '2021-01-28 00:12:20'),
(28, 7, 1, NULL, NULL, '2020-08-28', 'Springer - LipschitzLR: Using theoretically computed adaptive learning rates for fast convergence', 'Applied Intelligence', NULL, NULL, NULL, '3.325', NULL, NULL, NULL, NULL, 7, NULL, NULL, 0, 'https://doi.org/10.1007/s10489- 020-01892-0', '', '2021-01-27 01:58:05', '2021-01-28 00:13:24'),
(29, 7, 1, NULL, NULL, '2020-06-01', 'AIP- ChaosNet: A Chaos based Artificial Neural Network Architecture for Classification  (Editor’s collection)', 'Chaos: An Interdisciplinary Journal of Nonlinear Science', NULL, NULL, NULL, NULL, NULL, '29(11)', NULL, '113-125', 7, NULL, NULL, 0, NULL, '', '2021-01-27 02:12:24', '2021-01-28 00:15:00'),
(30, 7, 1, NULL, NULL, '2020-01-01', 'Elsevier – CESSA Meets Machine Learning: From Earth Similarity to Habitability Classification of Exoplanets', 'Astronomy and Computing', NULL, NULL, NULL, '3.1', NULL, '30', NULL, NULL, 7, NULL, NULL, 0, NULL, '', '2021-01-27 02:51:38', '2021-01-28 00:14:33'),
(31, 8, 1, NULL, 2, '2020-07-24', 'LALR: Theoretical and Experimental validation of Lipschitz Adaptive Learning Rate in Regression and Neural Networks', 'International Joint Conference on Neural Networks', 'Glasgow, United Kingdom, United Kingdom', 332, NULL, NULL, NULL, NULL, NULL, NULL, 7, NULL, NULL, 0, '10.1109/IJCNN48605.2020.9207650', '', '2021-01-27 03:08:12', '2021-01-27 03:08:12'),
(32, 8, 1, NULL, 2, '2020-07-24', 'Parsimonious Computing: A Minority Training Regime for Effective Prediction in Large Microarray Expression Data Sets', 'International Joint Conference on Neural Networks', NULL, 332, NULL, NULL, NULL, NULL, NULL, NULL, 7, NULL, NULL, 0, '10.1109/IJCNN48605.2020.9207083', '', '2021-01-27 03:11:46', '2021-01-27 03:11:46'),
(33, 8, 1, NULL, 2, '2020-05-01', 'Recruitment Boosted Epidemiological Model for Qualitative Study of Scholastic Influence Network', 'SIAM Conference on Mathematics of\r\nData Science', 'Cincinnati, USA', 328, NULL, NULL, NULL, NULL, NULL, NULL, 7, NULL, NULL, 0, NULL, '', '2021-01-27 03:21:44', '2021-01-27 03:21:44'),
(34, 8, 1, NULL, 2, '2020-05-01', 'Evolution of Novel Activation Functions', 'SIAM Conference on Mathematics of Data Science', 'Cincinnati, USA', 328, NULL, NULL, NULL, NULL, NULL, NULL, 7, NULL, NULL, 0, NULL, '', '2021-01-27 03:23:53', '2021-01-27 03:23:53'),
(35, 8, 1, NULL, 2, '2020-09-05', 'RaFIDe: A Machine Learning based RFI free observation\r\nplanner for the SKA Era', 'URSI GASS', 'Rome, Italy', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 7, NULL, NULL, 0, NULL, '', '2021-01-27 03:26:47', '2021-01-27 03:26:47');

-- --------------------------------------------------------

--
-- Table structure for table `pubuserdetails`
--

CREATE TABLE `pubuserdetails` (
  `pubid` bigint(20) UNSIGNED NOT NULL,
  `userid` bigint(20) UNSIGNED NOT NULL,
  `type` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `updated_date` date DEFAULT NULL,
  `updated_time` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `pubuserdetails`
--

INSERT INTO `pubuserdetails` (`pubid`, `userid`, `type`, `updated_date`, `updated_time`) VALUES
(4, 14, 'update', '2020-12-22', '07:47:43'),
(17, 19, 'update', '2020-12-23', '07:05:21'),
(10, 19, 'update', '2020-12-23', '07:06:35'),
(24, 9, 'update', '2020-12-30', '07:19:50'),
(27, 7, 'update', '2021-01-27', '07:20:10'),
(27, 7, 'update', '2021-01-27', '07:21:01'),
(27, 7, 'update', '2021-01-28', '05:42:08'),
(27, 7, 'update', '2021-01-28', '05:42:20'),
(28, 7, 'update', '2021-01-28', '05:43:24'),
(29, 7, 'update', '2021-01-28', '05:43:56'),
(30, 7, 'update', '2021-01-28', '05:44:33'),
(29, 7, 'update', '2021-01-28', '05:45:00');

-- --------------------------------------------------------

--
-- Table structure for table `rankings`
--

CREATE TABLE `rankings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ranking` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rankings`
--

INSERT INTO `rankings` (`id`, `ranking`, `created_at`, `updated_at`) VALUES
(248, 'Others', '2020-07-24 03:02:05', '2020-07-24 03:02:05'),
(321, 'Core A*', '2020-08-26 03:25:08', '2020-08-26 03:25:08'),
(326, 'Core B', '2020-08-26 23:42:13', '2020-08-26 23:42:13'),
(328, 'SCI', '2020-09-15 00:52:19', '2020-09-15 00:52:19'),
(329, 'SCIMAGO Q1', '2020-09-15 00:52:39', '2020-09-15 00:52:39'),
(330, 'SCIMAGO Q2', '2020-10-23 04:27:28', '2020-10-23 04:27:28'),
(332, 'Core A', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `userregistrations`
--

CREATE TABLE `userregistrations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userid` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campusid` bigint(20) UNSIGNED NOT NULL,
  `departmentid` bigint(20) UNSIGNED NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `remember_token` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `userregistrations`
--

INSERT INTO `userregistrations` (`id`, `userid`, `campusid`, `departmentid`, `password`, `remember_token`, `created_at`, `updated_at`) VALUES
(11, 'test123', 2, 4, '$2y$10$wPO5Bcr4vuncGu0rZTVTxOiwwZ4VeEmp3.oE/2pEZdw3tZZ/xWZ3O', NULL, '2020-10-23 00:11:01', '2020-10-23 00:11:01');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `google_id` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `avatar` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `avatar_original` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remember_token` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `google_id`, `name`, `email`, `email_verified_at`, `password`, `avatar`, `avatar_original`, `remember_token`, `created_at`, `updated_at`) VALUES
(7, '117396629326134053075', 'Neha Bipin Naik', 'nehan@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh6.googleusercontent.com/-N5SoqL5dqfQ/AAAAAAAAAAI/AAAAAAAAAAA/AMZuuckJDbzE6ol-gK3hZpqM53ChOdztaA/s96-c/photo.jpg', 'https://lh6.googleusercontent.com/-N5SoqL5dqfQ/AAAAAAAAAAI/AAAAAAAAAAA/AMZuuckJDbzE6ol-gK3hZpqM53ChOdztaA/s96-c/photo.jpg', NULL, '2020-11-25 23:16:31', '2020-11-25 23:16:31'),
(8, '105344646020903585601', 'Vinayak Naik', 'vinayak@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh3.googleusercontent.com/a-/AOh14GgeOBnBxGomNDSYcFd5GblGZPoA9vLr8NkejQfu=s96-c', 'https://lh3.googleusercontent.com/a-/AOh14GgeOBnBxGomNDSYcFd5GblGZPoA9vLr8NkejQfu=s96-c', NULL, '2020-12-19 15:52:09', '2020-12-19 15:52:09'),
(9, '112196717037723705921', 'Computer Sc. & I.S. Office', 'csis.office@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh3.googleusercontent.com/-Rbb4Szxyk0M/AAAAAAAAAAI/AAAAAAAAAAA/AMZuuclhO0jccEBGKRkibK1j0BgCwVp7jQ/s96-c/photo.jpg', 'https://lh3.googleusercontent.com/-Rbb4Szxyk0M/AAAAAAAAAAI/AAAAAAAAAAA/AMZuuclhO0jccEBGKRkibK1j0BgCwVp7jQ/s96-c/photo.jpg', NULL, '2020-12-20 18:00:05', '2020-12-20 18:00:05'),
(10, '108614930120870575515', 'Neena Goveas', 'neena@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh3.googleusercontent.com/a-/AOh14GgGckyBsbhnwIOtW9oCaMJvBnoAfRMD1Mv0bAv4dg=s96-c', 'https://lh3.googleusercontent.com/a-/AOh14GgGckyBsbhnwIOtW9oCaMJvBnoAfRMD1Mv0bAv4dg=s96-c', NULL, '2020-12-20 19:53:15', '2020-12-20 19:53:15'),
(11, '106338963609389113505', 'Soumyadip Bandyopadhyay', 'soumyadipb@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh3.googleusercontent.com/a-/AOh14GikJVvOyNjfOEa3M5J-6-gEw52hXdzrHmkz5StXSQ=s96-c', 'https://lh3.googleusercontent.com/a-/AOh14GikJVvOyNjfOEa3M5J-6-gEw52hXdzrHmkz5StXSQ=s96-c', NULL, '2020-12-20 20:45:14', '2020-12-20 20:45:14'),
(12, '118273853412958493525', 'Sanjay Kumar Sahay', 'ssahay@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh3.googleusercontent.com/a-/AOh14GjwJNoRtZJe1JWjLrw1tnqvIl5MqGjej0o8dtW6Mw=s96-c', 'https://lh3.googleusercontent.com/a-/AOh14GjwJNoRtZJe1JWjLrw1tnqvIl5MqGjej0o8dtW6Mw=s96-c', NULL, '2020-12-20 22:19:50', '2020-12-20 22:19:50'),
(13, '111778873346492546189', 'Hemant Rathore', 'hemantr@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh3.googleusercontent.com/-udYNyPdD7YY/AAAAAAAAAAI/AAAAAAAAAAA/AMZuucmhc135qSpaw2OZMo-TF4YRR4oqZA/s96-c/photo.jpg', 'https://lh3.googleusercontent.com/-udYNyPdD7YY/AAAAAAAAAAI/AAAAAAAAAAA/AMZuucmhc135qSpaw2OZMo-TF4YRR4oqZA/s96-c/photo.jpg', NULL, '2020-12-20 22:39:44', '2020-12-20 22:39:44'),
(14, '115375516415741930235', 'Tirtharaj Dash', 'tirtharaj@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh3.googleusercontent.com/a-/AOh14GjJjT5d08pGZZfE1Fvyjyg5yKgqXEnmP3e0Gp-u2g=s96-c', 'https://lh3.googleusercontent.com/a-/AOh14GjJjT5d08pGZZfE1Fvyjyg5yKgqXEnmP3e0Gp-u2g=s96-c', NULL, '2020-12-20 22:56:31', '2020-12-20 22:56:31'),
(15, '111103267545712699233', 'Danda Sravan', 'dandas@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh3.googleusercontent.com/a-/AOh14GhmF2FmZeXDFUrJrEOiNmQK1kxVydphrdloWJUg=s96-c', 'https://lh3.googleusercontent.com/a-/AOh14GhmF2FmZeXDFUrJrEOiNmQK1kxVydphrdloWJUg=s96-c', NULL, '2020-12-21 03:05:00', '2020-12-21 03:05:00'),
(16, '111221152687073615832', 'Kanchan Manna', 'kanchanm@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh4.googleusercontent.com/-hBLX3tcNb4s/AAAAAAAAAAI/AAAAAAAAAAA/AMZuucmU2xW_Tr_uKGI0_hSoAKiXdYRnKw/s96-c/photo.jpg', 'https://lh4.googleusercontent.com/-hBLX3tcNb4s/AAAAAAAAAAI/AAAAAAAAAAA/AMZuucmU2xW_Tr_uKGI0_hSoAKiXdYRnKw/s96-c/photo.jpg', NULL, '2020-12-21 14:50:35', '2020-12-21 14:50:35'),
(17, '117008660563332754602', 'Sujith Thomas', 'sujitht@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh3.googleusercontent.com/a-/AOh14GifC_fc0sk8pSgETZ-LsGyhEhW51TMXU6tS2DG2=s96-c', 'https://lh3.googleusercontent.com/a-/AOh14GifC_fc0sk8pSgETZ-LsGyhEhW51TMXU6tS2DG2=s96-c', NULL, '2020-12-21 16:33:07', '2020-12-21 16:33:07'),
(18, '110699123104851684458', 'Ramprasad S. Joshi', 'rsj@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh3.googleusercontent.com/a-/AOh14GiDmY61tSUb2MmjNugpW1cyesXKl_XPMGyFUZk65A=s96-c', 'https://lh3.googleusercontent.com/a-/AOh14GiDmY61tSUb2MmjNugpW1cyesXKl_XPMGyFUZk65A=s96-c', NULL, '2020-12-21 16:51:24', '2020-12-21 16:51:24'),
(19, '103828444953545563094', 'Raj Kumar Jaiswal', 'rajj@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh6.googleusercontent.com/-O8tefNkjBDc/AAAAAAAAAAI/AAAAAAAAAAA/AMZuuckjYUSl-qq0g50eTR87hPlFqQm89A/s96-c/photo.jpg', 'https://lh6.googleusercontent.com/-O8tefNkjBDc/AAAAAAAAAAI/AAAAAAAAAAA/AMZuuckjYUSl-qq0g50eTR87hPlFqQm89A/s96-c/photo.jpg', NULL, '2020-12-21 19:29:35', '2020-12-21 19:29:35'),
(20, '108469398427761706197', 'Ravindra Kumar Jangir', 'ravindrajangir@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh3.googleusercontent.com/a-/AOh14GidapPiOfKK6FY8fejXXCxSYX-g0uO0p9-fOKvnEQ=s96-c', 'https://lh3.googleusercontent.com/a-/AOh14GidapPiOfKK6FY8fejXXCxSYX-g0uO0p9-fOKvnEQ=s96-c', NULL, '2020-12-21 22:06:24', '2020-12-21 22:06:24'),
(21, '104413992366685476168', 'Baiju Krishnan', 'baijuk@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh3.googleusercontent.com/a-/AOh14GiX3-Vwg19YOJc_-EEchRoPOZLmWeEC6Wod5xhsUQ=s96-c', 'https://lh3.googleusercontent.com/a-/AOh14GiX3-Vwg19YOJc_-EEchRoPOZLmWeEC6Wod5xhsUQ=s96-c', NULL, '2020-12-22 18:40:08', '2020-12-22 18:40:08'),
(22, '106402616139062699440', 'Shreenivas A Naik', 'shreenivasn@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh3.googleusercontent.com/-hZ8kYLD85Rc/AAAAAAAAAAI/AAAAAAAAAAA/AMZuuclS-KRr5-DjhAHHoyY-YVBxDsMgIw/s96-c/photo.jpg', 'https://lh3.googleusercontent.com/-hZ8kYLD85Rc/AAAAAAAAAAI/AAAAAAAAAAA/AMZuuclS-KRr5-DjhAHHoyY-YVBxDsMgIw/s96-c/photo.jpg', NULL, '2020-12-22 18:49:54', '2020-12-22 18:49:54'),
(23, '116605258274397699792', 'Swati Agarwal', 'swatia@goa.bits-pilani.ac.in', NULL, NULL, 'https://lh3.googleusercontent.com/a-/AOh14GjpjE47iW8Kx2X6I-Hc_u4cAg-brvP3-o632vht=s96-c', 'https://lh3.googleusercontent.com/a-/AOh14GjpjE47iW8Kx2X6I-Hc_u4cAg-brvP3-o632vht=s96-c', NULL, '2020-12-29 00:23:54', '2020-12-29 00:23:54');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `articletypes`
--
ALTER TABLE `articletypes`
  ADD PRIMARY KEY (`articleid`),
  ADD UNIQUE KEY `articletypes_id_index` (`articleid`);

--
-- Indexes for table `authortypes`
--
ALTER TABLE `authortypes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `authirtypes_id_index` (`id`);

--
-- Indexes for table `broadareas`
--
ALTER TABLE `broadareas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `broadareas_id_index` (`id`);

--
-- Indexes for table `campuses`
--
ALTER TABLE `campuses`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `campuses_id_index` (`id`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `categories_id_index` (`id`);

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `departments_id_index` (`id`),
  ADD KEY `departments_campusid_foreign` (`campusid`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `impactfactors`
--
ALTER TABLE `impactfactors`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `impactfactors_id_index` (`id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD KEY `password_resets_email_index` (`email`);

--
-- Indexes for table `productprices`
--
ALTER TABLE `productprices`
  ADD PRIMARY KEY (`id`),
  ADD KEY `productprices_product_id_foreign` (`product_id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pubdtls`
--
ALTER TABLE `pubdtls`
  ADD PRIMARY KEY (`slno`,`pubhdrid`),
  ADD KEY `pubdtls_slno_index` (`slno`),
  ADD KEY `pubdtls_pubhdrid_foreign` (`pubhdrid`);

--
-- Indexes for table `pubhdrs`
--
ALTER TABLE `pubhdrs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `pubhdrs_pubhdrid_index` (`id`),
  ADD KEY `pubhdrs_categoryid_foreign` (`categoryid`),
  ADD KEY `pubhdrs_authortypeid_foreign` (`authortypeid`),
  ADD KEY `pubhdrs_rankingid_foreign` (`rankingid`),
  ADD KEY `pubhdrs_broadareaid_foreign` (`broadareaid`),
  ADD KEY `article_foreign` (`articletypeid`),
  ADD KEY `user_foreign` (`userid`);

--
-- Indexes for table `pubuserdetails`
--
ALTER TABLE `pubuserdetails`
  ADD KEY `pubuserdetails_pubid_index` (`pubid`) USING BTREE,
  ADD KEY `userid_foreign` (`userid`);

--
-- Indexes for table `rankings`
--
ALTER TABLE `rankings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `rankings_id_index` (`id`);

--
-- Indexes for table `userregistrations`
--
ALTER TABLE `userregistrations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `userregistrations_userid_unique` (`userid`),
  ADD UNIQUE KEY `userregistrations_id_index` (`id`),
  ADD KEY `userregistrations_campusid_foreign` (`campusid`),
  ADD KEY `userregistrations_departmentid_foreign` (`departmentid`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `articletypes`
--
ALTER TABLE `articletypes`
  MODIFY `articleid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `authortypes`
--
ALTER TABLE `authortypes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `broadareas`
--
ALTER TABLE `broadareas`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `campuses`
--
ALTER TABLE `campuses`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=125;

--
-- AUTO_INCREMENT for table `pubhdrs`
--
ALTER TABLE `pubhdrs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT for table `rankings`
--
ALTER TABLE `rankings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=333;

--
-- AUTO_INCREMENT for table `userregistrations`
--
ALTER TABLE `userregistrations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `departments`
--
ALTER TABLE `departments`
  ADD CONSTRAINT `departments_campusid_foreign` FOREIGN KEY (`campusid`) REFERENCES `campuses` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `pubhdrs`
--
ALTER TABLE `pubhdrs`
  ADD CONSTRAINT `user_foreign` FOREIGN KEY (`userid`) REFERENCES `users` (`id`);

--
-- Constraints for table `pubuserdetails`
--
ALTER TABLE `pubuserdetails`
  ADD CONSTRAINT `pubuserdetails_pubid_foreign` FOREIGN KEY (`pubid`) REFERENCES `pubhdrs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `userid_foreign` FOREIGN KEY (`userid`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `userregistrations`
--
ALTER TABLE `userregistrations`
  ADD CONSTRAINT `userregistrations_campusid_foreign` FOREIGN KEY (`campusid`) REFERENCES `campuses` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `userregistrations_departmentid_foreign` FOREIGN KEY (`departmentid`) REFERENCES `departments` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
