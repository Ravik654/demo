sp -
create or replace PROCEDURE "ADDUPDATEAOEANDIECPAYEEPAYEEMASTER" 
(
  v_PayeeId IN NUMBER DEFAULT 0 ,
  v_PayeeTitle IN NVARCHAR2 DEFAULT NULL ,
  v_PayeeName IN NVARCHAR2 DEFAULT NULL ,
  v_PayeeType IN NVARCHAR2 DEFAULT NULL ,
  v_MobilNumber IN NVARCHAR2 DEFAULT NULL ,
  v_Address IN NVARCHAR2 DEFAULT NULL ,
  v_EmailId varchar2 default null,
  v_BankName varchar2 default null,
  v_AccountNumber varchar2 default null,
  v_IFSCCode IN NVARCHAR2 DEFAULT NULL ,
  v_OtherPayeeType IN NVARCHAR2 DEFAULT NULL ,
  v_JobCardNumber IN NVARCHAR2 DEFAULT NULL ,
  v_FatherName IN NVARCHAR2 DEFAULT NULL,
  v_AadharNumber IN NVARCHAR2 DEFAULT NULL ,
  v_PAN varchar2 default null,
  v_TAN varchar2 default null,
  v_GSTIN varchar2 default null,
  v_PayeeStatus IN NUMBER DEFAULT NULL ,
  v_reviewStatus IN NUMBER,
  v_userId IN NUMBER DEFAULT 0 ,  
 v_WardId IN NVARCHAR2 DEFAULT NULL ,
 v_Status IN NUMBER DEFAULT 0,
 v_AccountType varchar2 default null,
  v_cursor out SYS_REFCURSOR
)
AS
   --v_PayeeAccountNumber NVARCHAR2(100) := iv_PayeeAccountNumber;
   v_checkerAccess NUMBER(1,0) := 0;
   v_Message VARCHAR2(100) ;
   v_CurrentPayeeId NUMBER;
   v_Fromcount Number;
   v_ToAcount Number;
   v_temp NUMBER:=0;
   v_checkerSelfPayee NUMBER:=0;
   v_adminRole NUMBER:=0;
   v_IsYesNo VARCHAR2(10);
   r_oldPayeeMaster AEOANDIECPAYEEMASTER%ROWTYPE;
   r_newPayeeMaster AEOANDIECPAYEEMASTEREdited%ROWTYPE;
   r_PayeeAccountType VARCHAR2(100);
   v_oldReviewStatus NUMBER(10);
   v_oldPayeeStatus NUMBER(10);
   v_newReviewStatus NUMBER(10);
   v_newPayeeStatus NUMBER(10);

BEGIN
   -- Checker 
   SELECT MAX(checker) INTO v_checkerAccess
   FROM UserRole ur
   JOIN RolesModule rm   ON ur.roleID = rm.roleID
   WHERE  ur.userId = v_userId AND moduleID = 550;
   -- Admin
   SELECT count(*) INTO v_adminRole FROM UserRole ur
   JOIN RolesModule rm ON ur.roleID = rm.roleID
   JOIN Roles r ON r.roleID = rm.roleID
   WHERE  moduleID = 550 AND r.roleName = 'GFBSAdmin' AND ur.userId = v_userId;

   --Payee Type
   --select  ATID into r_PayeeAccountType from AccountType where ATTYPE=v_PayeeAccountType;

   if(v_checkerAccess != 0) then
   BEGIN
   SELECT 1 INTO v_temp FROM DUAL WHERE EXISTS(SELECT 1 FROM AEOANDIECPAYEEMASTER WHERE PayeeId = v_PayeeId and createDBy = v_userId );
   EXCEPTION
      WHEN OTHERS THEN
     NULL;
   END;

    if(v_temp = 1)then
    begin
        v_checkerSelfPayee :=1;
    end;
    else
        v_checkerSelfPayee :=0;
    end if;
   end if;   

   IF ( v_PayeeId > 0 ) THEN
   BEGIN
      --When maker edit Payee information it will go to edit approval status  
      select * into r_oldpayeemaster from AEOANDIECPAYEEMASTER where  payeeid=v_PayeeId;
      select PayeeStatus into v_oldPayeeStatus from AEOANDIECPAYEEMASTER where  payeeid=v_PayeeId;
      select ReviewStatus into v_oldReviewStatus from AEOANDIECPAYEEMASTER where  payeeid=v_PayeeId;
      IF ( v_checkerAccess = 0 ) THEN
      BEGIN
         UPDATE AEOANDIECPAYEEMASTEREdited
            SET PAYEETITLE = v_PayeeTitle , PAYEENAME = v_PayeeName,   PAYEETYPE=v_PayeeType,
                    MOBILENumber = v_MobilNumber, EMAILID= v_EmailId,ADDRESS= v_Address,
                    BANKNAME = v_BankName,ACCOUNTNUMBER = v_AccountNumber,IFSCCODE= v_IFSCCode,OtherPayeeType=v_OtherPayeeType ,JobCardNumber=v_JobCardNumber, FATHERNAME = v_FatherName,AADHARNUMBER =v_AadharNumber,
                    PAN = v_PAN,TAN= v_TAN, GSTIN = v_GSTIN, ACCOUNTTYPE=v_AccountType,
                PayeeStatus = v_PayeeStatus,
                UpdatedDate = SYSDATE,PayeeId = v_PayeeId,
                UpdatedBy = v_userId,ReviewStatus = v_reviewStatus,
                WardId = v_WardId , Status = v_Status
          WHERE  PayeeId = v_PayeeId;

         UPDATE AEOANDIECPAYEEMASTER
            SET ReviewStatus = v_reviewStatus,UpdatedBy = v_userId,UpdatedDate = SYSDATE
          WHERE  PayeeId = v_PayeeId;

         IF ( v_reviewStatus = 1 OR v_reviewStatus = 4 OR v_reviewStatus = 7 ) THEN
         BEGIN
            UPDATE AEOANDIECPAYEEMASTER SET PayeeStatus = 2 WHERE  PayeeId = v_PayeeId;

            UPDATE AEOANDIECPAYEEMASTEREdited SET PayeeStatus = 2 WHERE  PayeeId = v_PayeeId;
         END;
         END IF;

         v_Message := 'Payee information has been sent to checker for review' ;
         OPEN v_cursor FOR
         SELECT v_PayeeId CurrentPayeeId, v_Message Message , v_reviewStatus reviewStatus FROM DUAL;
    END;
    ELSE
        --When checker review it will be in active or inactive
      DECLARE v_checkerEditDeleteStatus NUMBER(10,0) := 5;
      BEGIN
            IF(v_checkerSelfPayee = 0) then
            BEGIN
                    IF(v_PayeeStatus = 0 AND v_reviewStatus = 1 ) THEN
                       v_checkerEditDeleteStatus := 3 ;
                    END IF;

                    IF(v_PayeeStatus = 1 AND v_reviewStatus = 1 ) THEN
                       v_checkerEditDeleteStatus := 2 ;
                    END IF;

                    IF( v_PayeeStatus = 2 AND v_reviewStatus = 4 ) THEN
                        v_checkerEditDeleteStatus := 4;
                    END IF;

                     IF(v_PayeeStatus = 0 AND v_reviewStatus = 4 ) THEN
                      v_checkerEditDeleteStatus := 6 ;
                     END IF;

                     IF(v_PayeeStatus = 2 AND v_reviewStatus = 7 ) THEN
                      v_checkerEditDeleteStatus := 7 ;
                     END IF;

                     IF(v_PayeeStatus = 0 AND v_reviewStatus = 7 ) THEN
                      v_checkerEditDeleteStatus := 8 ;
                     END IF;

                      IF( v_PayeeStatus = 1 AND v_reviewStatus = 7 ) THEN
                      v_checkerEditDeleteStatus := 9 ;
                     END IF;
                     --PayeeMasterEdited
                     UPDATE AEOANDIECPAYEEMASTEREdited
                     SET  PAYEETITLE = v_PayeeTitle , PAYEENAME = v_PayeeName,   PAYEETYPE=v_PayeeType,
                    MOBILENumber = v_MobilNumber, EMAILID= v_EmailId,ADDRESS= v_Address,
                    BANKNAME= v_BankName,ACCOUNTNUMBER = v_AccountNumber,IFSCCODE= v_IFSCCode,OtherPayeeType=v_OtherPayeeType ,JobCardNumber=v_JobCardNumber, FATHERNAME=v_FatherName, AADHARNUMBER =v_AadharNumber,
                    PAN = v_PAN,TAN= v_TAN, GSTIN = v_GSTIN,ACCOUNTTYPE=v_AccountType,
                         PayeeStatus = v_PayeeStatus,
                         UpdatedDate = SYSDATE,PayeeId = v_PayeeId,
                         UpdatedBy = v_userId,ReviewStatus = v_checkerEditDeleteStatus,
                         WardId = v_WardId,
                          Status = v_Status
                     WHERE PayeeId = v_PayeeId;

                    --EditedRejected
                     IF(v_PayeeStatus = 0 AND v_reviewStatus = 4)THEN
                       BEGIN
                            UPDATE AEOANDIECPAYEEMASTER
                            SET ReviewStatus = 6 , PayeeStatus = 1 , UpdatedBy = v_userId , UpdatedDate = SYSDATE
                            WHERE  PayeeId = v_PayeeId;

                            UPDATE AEOANDIECPAYEEMASTEREdited ae2 SET (PAYEETITLE, PAYEENAME,   PAYEETYPE, MOBILENumber, EMAILID,ADDRESS, BANKNAME,ACCOUNTNUMBER,IFSCCODE ,AADHARNUMBER,PAN,TAN, GSTIN,
                                   UpdatedBy ,UpdatedDate , PayeeStatus ,ReviewStatus,WardId , Status ) = (
                                   SELECT PAYEETITLE, PAYEENAME,   PAYEETYPE, MOBILENumber, EMAILID,ADDRESS, BANKNAME,ACCOUNTNUMBER,IFSCCODE ,AADHARNUMBER,PAN,TAN, GSTIN,
                                       UpdatedBy ,UpdatedDate , 1 , 6 , WARDID, Status
                                   FROM AEOANDIECPAYEEMASTER ae1 WHERE ae1.PayeeId = ae2.PayeeId)WHERE  PayeeId = v_PayeeId;
                       END;
                     ELSE
                        BEGIN
                             UPDATE AEOANDIECPAYEEMASTER
                                SET  PAYEETITLE = v_PayeeTitle , PAYEENAME = v_PayeeName,   PAYEETYPE=v_PayeeType,
                    MOBILENumber = v_MobilNumber, EMAILID= v_EmailId,ADDRESS= v_Address,
                    BANKNAME = v_BankName,ACCOUNTNUMBER = v_AccountNumber,IFSCCODE= v_IFSCCode,OtherPayeeType=v_OtherPayeeType ,JobCardNumber=v_JobCardNumber, FATHERNAME = v_FatherName, AADHARNUMBER =v_AadharNumber,
                    PAN = v_PAN,TAN= v_TAN, GSTIN = v_GSTIN,ACCOUNTTYPE=v_AccountType,

                                    PayeeStatus = v_PayeeStatus,
                                    UpdatedDate = SYSDATE,UpdatedBy = v_userId,
                                    ReviewStatus = v_checkerEditDeleteStatus,
                                     Status = v_Status,
                                    WardId = v_WardId
                             WHERE  PayeeId = v_PayeeId;
                        END;
                    END IF;

                  if(v_PayeeStatus = 0 AND v_reviewStatus = 4) then
                        v_Message := 'Payee Rejected Successfully' ;
                  elsif(v_PayeeStatus = 0 AND v_reviewStatus = 1 ) then
                        v_Message := 'Payee Rejected Successfully' ;
                  elsif(v_PayeeStatus = 1 AND v_reviewStatus = 7 ) then
                        v_Message := 'Payee Rejected Successfully' ;      
                  else
                    v_Message := 'Payee verified Successfully' ;
                  end if; 
            END;
            ELSE
            BEGIN
                    IF ( v_PayeeStatus = 0 AND v_reviewStatus = 3 ) THEN
                      v_checkerEditDeleteStatus := 4;
                     END IF;

                     IF ( v_PayeeStatus = 1 AND v_reviewStatus = 2 ) THEN
                      v_checkerEditDeleteStatus := 4;
                     END IF;

                     IF ( v_PayeeStatus = 2 AND v_reviewStatus = 1 ) THEN
                      v_checkerEditDeleteStatus := 1;
                     END IF;

                     IF ( v_PayeeStatus = 1 AND v_reviewStatus = 6 ) THEN
                      v_checkerEditDeleteStatus := 4;
                     END IF;

                     IF ( v_PayeeStatus = 1 AND v_reviewStatus = 5 ) THEN
                      v_checkerEditDeleteStatus := 4;
                     END IF;

                     IF ( v_PayeeStatus = 2 AND v_reviewStatus = 4 ) THEN
                      v_checkerEditDeleteStatus := 4;
                     END IF;

                    IF ( v_PayeeStatus = 1 AND v_reviewStatus = 4 ) THEN
                      v_checkerEditDeleteStatus := 4;
                     END IF;

                      IF ( v_PayeeStatus = 0 AND v_reviewStatus = 8 ) THEN
                      v_checkerEditDeleteStatus := 4;
                     END IF;

                     IF ( v_PayeeStatus = 1 AND v_reviewStatus = 9 ) THEN
                      v_checkerEditDeleteStatus := 4;
                     END IF;

                     IF ( v_PayeeStatus = 2 AND v_reviewStatus = 7 ) THEN
                      v_checkerEditDeleteStatus := 4;
                     END IF;

                  UPDATE AEOANDIECPAYEEMASTEREdited
                    SET  PAYEETITLE = v_PayeeTitle , PAYEENAME = v_PayeeName,   PAYEETYPE=v_PayeeType,
                    MOBILENumber = v_MobilNumber, EMAILID= v_EmailId,ADDRESS= v_Address,
                    BANKNAME = v_BankName,ACCOUNTNUMBER = v_AccountNumber,IFSCCODE= v_IFSCCode,OtherPayeeType=v_OtherPayeeType ,JobCardNumber=v_JobCardNumber,FATHERNAME=v_FatherName, AADHARNUMBER =v_AadharNumber,
                    PAN = v_PAN,TAN= v_TAN, GSTIN = v_GSTIN,ACCOUNTTYPE=v_AccountType,
                        PayeeStatus = 2,
                        UpdatedDate = SYSDATE,
                        PayeeId = v_PayeeId,UpdatedBy = v_userId,ReviewStatus = v_checkerEditDeleteStatus,WardId = v_WardId, Status = v_Status

                  WHERE  PayeeId = v_PayeeId;

                 UPDATE AEOANDIECPAYEEMASTER
                    SET ReviewStatus = v_checkerEditDeleteStatus,PayeeStatus = 2,UpdatedBy = v_userId,UpdatedDate = SYSDATE
                  WHERE  PayeeId = v_PayeeId;

        --         IF ( v_reviewStatus = 1
        --           OR v_reviewStatus = 4
        --           OR v_reviewStatus = 7 ) THEN
        --
        --         BEGIN
        --            UPDATE PayeeMaster
        --               SET PayeeStatus = 2
        --             WHERE  PayeeId = v_PayeeId;
        --            UPDATE PayeeMasterEdited
        --               SET PayeeStatus = 2
        --             WHERE  PayeeId = v_PayeeId;
        --         END;
        --         END IF;
        END;
            END IF;

        --if(v_checkerSelfPayee = 0) then
         --v_Message := 'Payee Updated Successfully' ;
        --else
         --v_Message := 'Payee information has been sent to checker for review.' ;
        --end if;

                  if(v_checkerSelfPayee = 1) then
                        v_Message := 'Payee information has been sent to checker for review';

                 if(v_adminRole = 1 and (v_reviewStatus in (1,4,7)))then
                  if((v_PayeeStatus = 0 AND v_reviewStatus = 4 and v_adminRole = 1) or (v_PayeeStatus = 0 AND v_reviewStatus = 1 and v_adminRole = 1)
                  or(v_PayeeStatus = 1 AND v_reviewStatus = 7 and v_adminRole = 1 )) then
                        v_Message := 'Payee Rejected Successfully' ;
                  else
                    v_Message := 'Payee verified Successfully' ; 
                  end if;  
             end if;           
        end if;

         OPEN v_cursor FOR
         SELECT v_PayeeId CurrentPayeeId, v_Message Message, v_checkerEditDeleteStatus reviewStatus FROM DUAL;

      END;
      END IF;
      --here  
-------------------------------insert audit history
       ---for checker

IF ( v_checkerAccess != 0 AND (v_reviewStatus=4 OR v_reviewStatus=1 OR v_reviewStatus=7)) THEN
BEGIN
select * into r_newPayeeMaster from AEOANDIECPAYEEMASTEREDITED where  payeeid=v_PayeeId;
select PayeeStatus into v_newPayeeStatus from AEOANDIECPAYEEMASTER where  payeeid=v_PayeeId;
select ReviewStatus into v_newReviewStatus from AEOANDIECPAYEEMASTER where  payeeid=v_PayeeId;
--select * into r_oldpayeemaster from AEOANDIECPAYEEMASTER where  payeeid=v_PayeeId;
INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)
    SELECT v_PayeeId, 
    'Request Type' , 
    CASE 
    WHEN v_oldReviewStatus = 1 THEN 'Add approval pending'
    WHEN v_oldReviewStatus = 2 THEN 'Add Approved'
    WHEN v_oldReviewStatus = 3 THEN 'Add rejected'
    WHEN v_oldReviewStatus = 4 THEN 'Edit approval pending'
    WHEN v_oldReviewStatus = 5 THEN 'Edit Approved'
    WHEN v_oldReviewStatus = 6 THEN 'Edit rejected'
    WHEN v_oldReviewStatus = 7 THEN 'Delete approval pending'
    WHEN v_oldReviewStatus = 8 THEN 'Delete Approved'
    WHEN v_oldReviewStatus = 9 THEN 'Delete rejected' 
    END , 
    CASE 
    WHEN v_newReviewStatus = 1 THEN 'Add approval pending'
    WHEN v_newReviewStatus = 2 THEN 'Add Approved'
    WHEN v_newReviewStatus = 3 THEN 'Add rejected'
    WHEN v_newReviewStatus = 4 THEN 'Edit approval pending'
    WHEN v_newReviewStatus = 5 THEN 'Edit Approved'
    WHEN v_newReviewStatus = 6 THEN 'Edit rejected'
    WHEN v_newReviewStatus = 7 THEN 'Delete approval pending'
    WHEN v_newReviewStatus = 8 THEN 'Delete Approved'
    WHEN v_newReviewStatus = 9 THEN 'Delete rejected' 
    END , 
    1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
    END;
    BEGIN
INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)
    SELECT v_PayeeId, 
    'Status' , 
    CASE 
    WHEN v_oldPayeeStatus = 1 THEN 'Active' WHEN v_oldPayeeStatus = 0 THEN 'Inactive' WHEN v_oldPayeeStatus = 2 THEN 'Pending'
    END , 
    CASE 
    WHEN v_newPayeeStatus = 1 THEN 'Active' WHEN v_newPayeeStatus = 0 THEN 'Inactive' WHEN v_newPayeeStatus = 2 THEN 'Pending' 
    END , 
    1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
    END;
END IF;
       ---for maker
if(v_checkerAccess = 0 AND v_reviewStatus =4)then
SELECT * INTO r_newPayeeMaster FROM AEOANDIECPAYEEMASTEREDITED WHERE PayeeId = v_PayeeId ;
select * into r_oldpayeemaster from AEOANDIECPAYEEMASTER where  payeeid=v_PayeeId;
select PayeeStatus into v_newPayeeStatus from AEOANDIECPAYEEMASTER where  payeeid=v_PayeeId;
select ReviewStatus into v_newReviewStatus from AEOANDIECPAYEEMASTER where  payeeid=v_PayeeId;
               BEGIN
                        IF(NVL(r_oldPayeeMaster.PayeeName,'') != NVL(r_newPayeeMaster.PayeeName,''))THEN
                            BEGIN
                                INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)        
                                SELECT v_PayeeId, 'Payee Name' , r_oldPayeeMaster.PayeeName , r_newPayeeMaster.PayeeName , 1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
                            END;
                        END IF;
                        IF(NVL(r_oldPayeeMaster.PayeeTitle,'')  != NVL(r_newPayeeMaster.PayeeTitle,''))THEN
                            BEGIN
                                INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)        
                                SELECT v_PayeeId, 'Payee Title' , r_oldPayeeMaster.PayeeTitle , r_newPayeeMaster.PayeeTitle , 1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
                            END;
                        END IF;
                        IF(NVL(r_oldPayeeMaster.MobileNumber,'') != NVL(r_newPayeeMaster.MobileNumber,''))THEN
                            BEGIN
                                INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)        
                                SELECT v_PayeeId, 'Mobile' , r_oldPayeeMaster.MobileNumber , r_newPayeeMaster.MobileNumber , 1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
                            END;
                        END IF;
                         IF(NVL(r_oldPayeeMaster.IFSCCode,'') != NVL(r_newPayeeMaster.IFSCCode,''))THEN
                            BEGIN
                                INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)        
                                SELECT v_PayeeId, 'IFSCCode' , r_oldPayeeMaster.IFSCCode ,  r_newPayeeMaster.IFSCCode, 1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
                            END;
                        END IF;

                        IF(NVL(r_oldPayeeMaster.OtherPayeeType,'') != NVL(r_newPayeeMaster.OtherPayeeType,''))THEN
                            BEGIN
                                INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)        
                                SELECT v_PayeeId, 'Expense Payee' , r_oldPayeeMaster.OtherPayeeType ,  r_newPayeeMaster.OtherPayeeType, 1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
                            END;
                        END IF;

                       IF(NVL(r_oldPayeeMaster.AccountNumber,'') != NVL(r_newPayeeMaster.AccountNumber,''))THEN
                            BEGIN
                                INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)        
                                SELECT v_PayeeId, 'Account Number' , r_oldPayeeMaster.AccountNumber , r_newPayeeMaster.AccountNumber , 1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
                            END;
                        END IF;



                       IF( NVL(r_oldPayeeMaster.BankName,'') != NVL(r_newPayeeMaster.BankName,''))THEN
                            BEGIN
                                INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)        
                                SELECT v_PayeeId, 'Bank Name' , r_oldPayeeMaster.BankName , r_newPayeeMaster.BankName , 1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
                            END;
                        END IF;     

                       IF( COALESCE(r_oldPayeeMaster.Address, '') != COALESCE(r_newPayeeMaster.Address,''))THEN
                            BEGIN
                                INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)        
                                SELECT v_PayeeId, 'Address' , r_oldPayeeMaster.Address , r_newPayeeMaster.Address , 1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
                            END;
                        END IF;  

                      IF(NVL(r_oldPayeeMaster.EmailId,'') != NVL(r_newPayeeMaster.EmailId,''))THEN
                            BEGIN
                                INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)        
                                SELECT v_PayeeId, 'EmailId' , r_oldPayeeMaster.EmailId , r_newPayeeMaster.EmailId , 1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
                            END;
                        END IF;

                        IF(NVL(r_oldPayeeMaster.PayeeType,'') != NVL(r_newPayeeMaster.PayeeType,''))THEN
                            BEGIN
                                INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)        
                                SELECT v_PayeeId, 'Payee Type' , r_oldPayeeMaster.PayeeType, r_newPayeeMaster.PayeeType , 1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
                            END;
                        END IF;
                        IF(NVL(r_oldPayeeMaster.FatherName,'') != NVL(r_newPayeeMaster.FatherName,''))THEN
                            BEGIN
                                INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)        
                                SELECT v_PayeeId, 'Father Name' , r_oldPayeeMaster.FatherName, r_newPayeeMaster.FatherName , 1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
                            END;
                        END IF;
                           IF(NVL(r_oldPayeeMaster.ACCOUNTTYPE,'') != NVL(r_newPayeeMaster.ACCOUNTTYPE,''))THEN
                            BEGIN
                                INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)        
                                SELECT v_PayeeId, 'Account Type' , r_oldPayeeMaster.ACCOUNTTYPE, r_newPayeeMaster.ACCOUNTTYPE , 1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
                            END;
                        END IF;
                        END;
    BEGIN
    INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)
    SELECT v_PayeeId, 
    'Request Type' , 
    CASE 
    WHEN v_oldreviewstatus = 1 THEN 'Add approval pending'
    WHEN v_oldreviewstatus = 2 THEN 'Add Approved'
    WHEN v_oldreviewstatus = 3 THEN 'Add rejected'
    WHEN v_oldreviewstatus = 4 THEN 'Edit approval pending'
    WHEN v_oldreviewstatus = 5 THEN 'Edit Approved'
    WHEN v_oldreviewstatus = 6 THEN 'Edit rejected'
    WHEN v_oldreviewstatus = 7 THEN 'Delete approval pending'
    WHEN v_oldreviewstatus = 8 THEN 'Delete Approved'
    WHEN v_oldreviewstatus = 9 THEN 'Delete rejected' 
    END , 
    CASE 
    WHEN v_newreviewstatus = 1 THEN 'Add approval pending'
    WHEN v_newreviewstatus  = 2 THEN 'Add Approved'
    WHEN v_newreviewstatus  = 3 THEN 'Add rejected'
    WHEN v_newreviewstatus  = 4 THEN 'Edit approval pending'
    WHEN v_newreviewstatus  = 5 THEN 'Edit Approved'
    WHEN v_newreviewstatus  = 6 THEN 'Edit rejected'
    WHEN v_newreviewstatus  = 7 THEN 'Delete approval pending'
    WHEN v_newreviewstatus  = 8 THEN 'Delete Approved'
    WHEN v_newreviewstatus  = 9 THEN 'Delete rejected' 
    END , 
    1 , r_newPayeeMaster.Createdby  , SYSDATE FROM DUAL;
    END;
    BEGIN
INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)
    SELECT v_PayeeId, 
    'Status' , 
    CASE 
    WHEN v_oldpayeestatus = 1 THEN 'Active' WHEN v_oldpayeestatus = 0 THEN 'Inactive' WHEN v_oldpayeestatus = 2 THEN 'Pending'
    END , 
    CASE 
    WHEN v_newpayeestatus = 1 THEN 'Active' WHEN v_newpayeestatus = 0 THEN 'Inactive' WHEN v_newpayeestatus = 2 THEN 'Pending' 
    END , 
    1 , r_oldPayeeMaster.createdBy , SYSDATE FROM DUAL;
    END;
      END IF;
----End Insert Audit History

   END;
   ELSE
   BEGIN
      --Maker when add Payee                      
      IF ( v_checkerAccess = 0 or v_checkerAccess != 0) THEN
      BEGIN
         INSERT INTO AEOANDIECPAYEEMASTER
           ( PAYEETITLE, PAYEENAME,   PAYEETYPE, MOBILENumber, EMAILID,ADDRESS, BANKNAME,ACCOUNTNUMBER,IFSCCODE,OtherPayeeType ,
           JobCardnumber,FATHERNAME, ACCOUNTTYPE, AADHARNUMBER,PAN,TAN, GSTIN, 
           PAYEEStatus ,CreatedDate, CreatedBy, ReviewStatus,WardId ,Status,UlbId)
           VALUES ( v_PayeeTitle,v_PayeeName,   v_PayeeType, v_MobilNumber, v_EmailId,  v_Address, v_BankName, v_AccountNumber,v_IFSCCode,
           v_OtherPayeeType,v_JobCardNumber,v_FatherName,v_AccountType, v_AadharNumber,v_PAN ,v_TAN,v_GSTIN,
            v_PayeeStatus, SYSDATE, v_userId, 1,v_WardId,  v_Status,(select ulbid from usermaster where userid=v_userId))RETURNING PayeeId INTO v_CurrentPayeeId;


         INSERT INTO AEOANDIECPAYEEMASTEREdited
           ( PayeeId, PAYEETITLE, PAYEENAME,   PAYEETYPE, MOBILENumber, EMAILID,ADDRESS, BANKNAME,ACCOUNTNUMBER,IFSCCODE, OtherPayeeType ,JobCardnumber,FATHERNAME,ACCOUNTTYPE, AADHARNUMBER,PAN,TAN, GSTIN, 
           PAYEEStatus ,CreatedDate, CreatedBy, ReviewStatus,WardId,Status,UlbId)
           VALUES ( v_CurrentPayeeId,v_PayeeTitle,v_PayeeName,   v_PayeeType, v_MobilNumber, v_EmailId,  v_Address, v_BankName, v_AccountNumber,v_IFSCCode,v_OtherPayeeType,v_JobCardNumber, v_FatherName,v_AccountType, v_AadharNumber,v_PAN ,v_TAN,v_GSTIN,
            v_PayeeStatus, SYSDATE, v_userId, 1,v_WardId,v_Status,(select ulbid from usermaster where userid=v_userId));
         v_Message := 'Payee information has been sent to checker for review' ;


        INSERT INTO aeoandiecpayeeaudithistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)        
        SELECT v_CurrentPayeeId, 'Job Card Number' ,'', TO_CHAR(v_JobCardNumber) , 3 , v_userId , SYSDATE FROM DUAL WHERE v_JobCardNumber is not null
        UNION ALL 
        SELECT v_CurrentPayeeId, 'Ward' ,'', TO_CHAR((SELECT WARDNUMBER FROM WARDMASTER WHERE WARDID = v_WardId and rownum =1 )) , 3 , v_userId , SYSDATE FROM DUAL WHERE v_WardId is not null
        UNION ALL 
        SELECT v_CurrentPayeeId, 'Request Type' ,'', 'Add approval pending' , 3 , v_userId , SYSDATE FROM DUAL
        UNION ALL 
        SELECT v_CurrentPayeeId, 'Status' , '' ,TO_CHAR((CASE WHEN v_Status = 1 THEN 'Active' WHEN v_Status = 0 THEN 'Inactive' WHEN v_Status = 2 THEN 'Pending' END)) , 3 , v_userId , SYSDATE FROM DUAL WHERE v_Status IS NOT NULL
        UNION ALL 
        SELECT v_CurrentPayeeId, 'Payee Type' , '', TO_CHAR(v_OtherPayeeType), 3 , v_userId , SYSDATE FROM DUAL
        UNION ALL 
        SELECT v_CurrentPayeeId, 'EmailId' , '' , TO_CHAR(v_EmailId) , 3 , v_userId , SYSDATE FROM DUAL WHERE v_EmailId IS NOT NULL
        UNION ALL 
        SELECT v_CurrentPayeeId, 'Address' , '' , TO_CHAR(v_Address) , 3 , v_userId , SYSDATE FROM DUAL WHERE v_Address IS NOT NULL
        UNION ALL 
        SELECT v_CurrentPayeeId, 'Bank Name' , '' , TO_CHAR(v_BankName) , 3 , v_userId , SYSDATE FROM DUAL
        UNION ALL 
        SELECT v_CurrentPayeeId, 'Adhaar Number' , '' ,TO_CHAR( v_AadharNumber) , 3 , v_userId , SYSDATE FROM DUAL WHERE v_AadharNumber IS NOT NULL
        UNION ALL 
        SELECT v_CurrentPayeeId, 'Account Number' , '' ,TO_CHAR( v_AccountNumber) , 3 , v_userId , SYSDATE FROM DUAL
        UNION ALL 
        SELECT v_CurrentPayeeId, 'Expense Type' , '' ,  TO_CHAR(v_PayeeType), 3 , v_userId , SYSDATE FROM DUAL
        UNION ALL 
        SELECT v_CurrentPayeeId, 'IFSCCode' , '' , TO_CHAR( v_IFSCCode), 3 , v_userId , SYSDATE FROM DUAL
        UNION ALL 
        SELECT v_CurrentPayeeId, 'Mobile Number' , '' , TO_CHAR(v_MobilNumber) , 3 , v_userId , SYSDATE FROM DUAL WHERE v_MobilNumber IS NOT NULL
        UNION ALL 
        SELECT v_CurrentPayeeId, 'Payee Title' , '' , TO_CHAR(v_PayeeTitle) , 3 , v_userId , SYSDATE FROM DUAL
        UNION ALL 
        SELECT v_CurrentPayeeId, 'Payee Name' , '' , TO_CHAR(v_PayeeName) , 3 , v_userId , SYSDATE FROM DUAL
        UNION ALL
        SELECT v_CurrentPayeeId, 'Father Name', '', TO_CHAR(v_FatherName), 3 ,v_userId, SYSDATE FROM DUAL Where v_FatherName IS NOT NULL
         UNION ALL 
        SELECT v_CurrentPayeeId , 'AccountType' , '',TO_CHAR(v_AccountType),3 , v_userId , SYSDATE FROM DUAL;
                                


         OPEN v_cursor FOR
         SELECT v_CurrentPayeeId CurrentPayeeId, v_Message Message , 1 reviewStatus FROM DUAL;
      END;
      END IF;
           -- Add Data PayeeAuditHistory Table
            --INSERT INTO PayeeAuditHistory(PayeeId , fieldName , oldValue , newValue ,action , createdBy , createdDate)        
           -- SELECT v_CurrentPayeeId, '' , '' , '' , 0 , v_userId , SYSDATE FROM DUAL;
   END;
   END IF;



END;
