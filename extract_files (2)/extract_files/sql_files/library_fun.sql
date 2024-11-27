-- -- -- -- LIBRARY.SQL

-- -- Function: Get Password
-- CREATE OR REPLACE FUNCTION getPassword(tableName VARCHAR2, userField VARCHAR2, userName VARCHAR2)
-- RETURN VARCHAR2
-- IS
--   resultPassword VARCHAR2(100);
-- BEGIN
--   EXECUTE IMMEDIATE 'SELECT password FROM ' || tableName || ' WHERE ' || userField || ' = :1' 
--   INTO resultPassword USING userName;
--   RETURN resultPassword;
-- EXCEPTION
--   WHEN no_data_found THEN
--     RETURN NULL;
-- END;

-- -- Function: Check Item Type
-- CREATE OR REPLACE FUNCTION getItemType(itemId VARCHAR2)
-- RETURN VARCHAR2
-- IS
--   itemType VARCHAR2(10);
-- BEGIN
--   IF EXISTS(SELECT 1 FROM book WHERE bookid = itemId) THEN
--     RETURN 'BOOK';
--   ELSIF EXISTS(SELECT 1 FROM video WHERE videoid = itemId) THEN
--     RETURN 'VIDEO';
--   ELSE
--     RETURN 'UNKNOWN';
--   END IF;
-- END;

-- -- Function: Get Item Details
-- FUNCTION  getItemDetails(itemId VARCHAR2, itemType VARCHAR2)
-- RETURN SYS_REFCURSOR
-- IS
--   details SYS_REFCURSOR;
-- BEGIN
--   IF itemType = 'BOOK' THEN
--     OPEN details FOR
--     SELECT isbn, state, avalability, debycost, lostcost, address
--     FROM book
--     WHERE bookid = itemId;
--   ELSIF itemType = 'VIDEO' THEN
--     OPEN details FOR
--     SELECT title, year, state, avalability, debycost, lostcost, address
--     FROM video
--     WHERE videoid = itemId;
--   ELSE
--     RAISE_APPLICATION_ERROR(-20001, 'Unknown item type');
--   END IF;
--   RETURN details;
-- END;

-- Procedure: Login Customer
PROCEDURE loginCustomer_library(user IN VARCHAR2, pass IN VARCHAR2)
IS
  passAux VARCHAR2(100);
  incorrect_password EXCEPTION;
BEGIN
  passAux := getPassword('customer', 'username', user);
  
  IF passAux IS NULL OR passAux <> pass THEN
    RAISE incorrect_password;
  END IF;

  DBMS_OUTPUT.PUT_LINE('User ' || user || ' login successful');
  
EXCEPTION
  WHEN incorrect_password THEN
    DBMS_OUTPUT.PUT_LINE('Incorrect username or password');
END;

-- Procedure: Login Employee
PROCEDURE loginEmployee_library(user IN VARCHAR2, pass IN VARCHAR2)
IS
  passAux VARCHAR2(100);
  incorrect_password EXCEPTION;
BEGIN
  passAux := getPassword('employee', 'username', user);

  IF passAux IS NULL OR passAux <> pass THEN
    RAISE incorrect_password;
  END IF;

  DBMS_OUTPUT.PUT_LINE('User ' || user || ' login successful');
  
EXCEPTION
  WHEN incorrect_password THEN
    DBMS_OUTPUT.PUT_LINE('Incorrect username or password');
END;

-- Procedure: View Item Details
PROCEDURE viewItem_library(itemId IN VARCHAR2)
IS
  itemType VARCHAR2(10);
  itemDetails SYS_REFCURSOR;
  recDetails RECORD;
BEGIN
  itemType := getItemType(itemId);
  itemDetails := getItemDetails(itemId, itemType);

  DBMS_OUTPUT.PUT_LINE(itemType || ' ' || itemId || ' INFO');
  DBMS_OUTPUT.PUT_LINE('------------------------------------------');
  LOOP
    FETCH itemDetails INTO recDetails;
    EXIT WHEN itemDetails%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(recDetails);
  END LOOP;
  CLOSE itemDetails;
  DBMS_OUTPUT.PUT_LINE('------------------------------------------');
END;

-- Procedure: Customer Account
 PROCEDURE customerAccount_library(custId IN customer.customerid%TYPE)
IS
  auxCard NUMBER;
  auxFines NUMBER;
  auxItem VARCHAR2(6);
  rented NUMBER := 0;
BEGIN
  SELECT cardnumber INTO auxCard
  FROM customer
  WHERE customerid = custId;
  
  SELECT COUNT(*) INTO rented
  FROM rent
  WHERE rent.cardid = auxCard;
  
  DBMS_OUTPUT.PUT_LINE('The user card is ' || auxCard);  
  IF rented > 0 THEN
    SELECT itemid INTO auxItem
    FROM rent
    WHERE cardid = auxCard;    
    DBMS_OUTPUT.PUT_LINE('The user has ' || auxItem || ' rented');
  ELSE    
    DBMS_OUTPUT.PUT_LINE('This user has no rents'); 
  END IF;
  
  SELECT fines INTO auxFines
  FROM card
  WHERE cardid = auxCard;
  
  DBMS_OUTPUT.PUT_LINE('The user fines are ' || auxFines);
    
EXCEPTION
  WHEN no_data_found THEN 
    DBMS_OUTPUT.PUT_LINE('NOT DATA FOUND');
END;

-- Procedure: Employee Account
PROCEDURE employeeAccount_library(empId IN employee.employeeid%TYPE)
IS
  auxCard NUMBER;
  auxFines NUMBER;
  auxItem VARCHAR2(6);
  rented NUMBER := 0;
BEGIN
  SELECT cardnumber INTO auxCard
  FROM employee
  WHERE employeeid = empId;
  
  SELECT COUNT(*) INTO rented
  FROM rent
  WHERE rent.cardid = auxCard;
  
  DBMS_OUTPUT.PUT_LINE('The user card is ' || auxCard);  
  IF rented > 0 THEN
    SELECT itemid INTO auxItem
    FROM rent
    WHERE cardid = auxCard;    
    DBMS_OUTPUT.PUT_LINE('The user has ' || auxItem || ' rented');
  ELSE    
    DBMS_OUTPUT.PUT_LINE('This user has no rents'); 
  END IF;
  
  SELECT fines INTO auxFines
  FROM card
  WHERE cardid = auxCard;
  
  DBMS_OUTPUT.PUT_LINE('The user fines are ' || auxFines);
    
EXCEPTION
  WHEN no_data_found THEN 
    DBMS_OUTPUT.PUT_LINE('NOT DATA FOUND');
END;

-- LIBRARY.SQL

-- Sub-Procedure: Update Item Availability
PROCEDURE updateItemAvailability(itemType IN VARCHAR2, itemId IN VARCHAR2, newStatus IN VARCHAR2)
IS
BEGIN
  IF itemType = 'book' THEN
    UPDATE book
    SET avalability = newStatus
    WHERE bookid = itemId;
  ELSIF itemType = 'video' THEN
    UPDATE video
    SET avalability = newStatus
    WHERE videoid = itemId;
  ELSE
    RAISE_APPLICATION_ERROR(-20002, 'Unknown item type');
  END IF;
END;

-- Sub-Procedure: Validate Card Status
PROCEDURE validateCardStatus(auxCard IN NUMBER)
IS
  cardStatus VARCHAR2(1);
BEGIN
  SELECT status INTO cardStatus
  FROM card
  WHERE cardid = auxCard;

  IF cardStatus != 'A' THEN
    DBMS_OUTPUT.PUT_LINE('Card is blocked or inactive.');
    RAISE_APPLICATION_ERROR(-20003, 'Card is not active');
  END IF;
END;

-- Procedure: Rent Item
PROCEDURE rentItem_library(auxCard IN NUMBER, auxItemID IN VARCHAR2, itemType IN VARCHAR2, auxDate IN DATE)
IS
  itemStatus VARCHAR2(1);
BEGIN
  -- Validate card status
  validateCardStatus(auxCard);

  -- Check item availability
  IF itemType = 'book' THEN
    SELECT avalability INTO itemStatus
    FROM book
    WHERE bookid = auxItemID;
  ELSIF itemType = 'video' THEN
    SELECT avalability INTO itemStatus
    FROM video
    WHERE videoid = auxItemID;
  ELSE
    RAISE_APPLICATION_ERROR(-20002, 'Unknown item type');
  END IF;

  IF itemStatus = 'A' THEN
    -- Update availability
    updateItemAvailability(itemType, auxItemID, 'O');

    -- Insert rental record
    INSERT INTO rent (cardid, itemid, rent_date, return_date)
    VALUES (auxCard, auxItemID, SYSDATE, auxDate);
    DBMS_OUTPUT.PUT_LINE('Item ' || auxItemID || ' rented successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Item ' || auxItemID || ' is already rented');
  END IF;
END;

-- Sub-Procedure: Update Card Fines
PROCEDURE updateCardFines(auxCard IN card.cardid%TYPE, newFines IN NUMBER)
IS
BEGIN
  UPDATE card
  SET fines = newFines
  WHERE cardid = auxCard;

  IF newFines = 0 THEN
    UPDATE card
    SET status = 'A'
    WHERE cardid = auxCard;
  END IF;
END;

-- Procedure: Pay Fines
 PROCEDURE payFines_library(auxCard IN card.cardid%TYPE, money IN NUMBER)
IS
  finesAmount NUMBER;
  remainingFines NUMBER;
BEGIN
  SELECT fines INTO finesAmount
  FROM card
  WHERE cardid = auxCard;

  IF money >= finesAmount THEN
    remainingFines := 0;
    DBMS_OUTPUT.PUT_LINE('All fines paid. Remaining balance: ' || (money - finesAmount));
  ELSE
    remainingFines := finesAmount - money;
    DBMS_OUTPUT.PUT_LINE('Partial payment made. Remaining fines: ' || remainingFines);
  END IF;

  -- Update fines via sub-procedure
  updateCardFines(auxCard, remainingFines);
END;

-- Anonymous Block for Rent Item
SET SERVEROUTPUT ON;
BEGIN
  rentItem_library(&Card_ID, &ID_Item, '&Item_Type_book_or_video', &Return_Date);
END;

-- Anonymous Block for Pay Fines
SET SERVEROUTPUT ON;
BEGIN
  payFines_library(&Card_ID, &Payment_Amount);
END;


