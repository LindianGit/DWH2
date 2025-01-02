USE externalDB2;
GO

-- Drop the stored procedure if it already exists
IF OBJECT_ID('dbo.LoadExternalDWH', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.LoadExternalDWH;
END
GO

/*
    Stored Procedure: LoadExternalDWH
    Author: Lindian Carlos
    Created Date: 2025-01-02

    Description:
    This stored procedure is designed to load sample data into the externalDWH schema of the externalDB2 database.
    It performs the following tasks:
    1. Deletes existing data from the tables in the correct order to avoid foreign key constraint violations.
    2. Inserts sample data into the Date, Region, Customer, Transactions, Inventory, and Sale tables.

    Usage:
    To load the sample data, simply execute the stored procedure:
    EXEC dbo.LoadExternalDWH;
*/

-- Create stored procedure to load sample data
CREATE PROCEDURE dbo.LoadExternalDWH
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Clear existing data from tables in the correct order to avoid foreign key violations
        DELETE FROM externalDWH.Sale;
        DELETE FROM externalDWH.Transactions;
        DELETE FROM externalDWH.Inventory;
        DELETE FROM externalDWH.Customer;
        DELETE FROM externalDWH.Date;
        DELETE FROM externalDWH.Region;

        -- Insert sample data into Date table
        INSERT INTO externalDWH.Date (DateKey, Date, Year, Quarter, Month, Day, Week, DayOfWeek, IsWeekend)
        VALUES 
        (20250101, '2025-01-01', 2025, 1, 1, 1, 1, 3, 0),
        (20250102, '2025-01-02', 2025, 1, 1, 2, 1, 4, 0);

        -- Insert sample data into Region table
        INSERT INTO externalDWH.Region (RegionID, RegionName)
        VALUES 
        (1, 'North America'),
        (2, 'Europe');

        -- Insert sample data into Customer table
        INSERT INTO externalDWH.Customer (CustomerID, FirstName, LastName, Email, Phone, JoinDate, RegionID)
        VALUES 
        (1, 'John', 'Doe', 'john.doe@example.com', '123-456-7890', '2024-12-01', 1),
        (2, 'Jane', 'Smith', 'jane.smith@example.com', '098-765-4321', '2024-12-15', 2);

        -- Insert sample data into Transactions table
        INSERT INTO externalDWH.Transactions (TransactionID, StoreID, ProductID, Quantity, Price, Timestamp)
        VALUES 
        (1, 101, 1001, 2, 19.99, '2025-01-01 10:00:00'),
        (2, 102, 1002, 1, 9.99, '2025-01-01 11:00:00');

        -- Insert sample data into Inventory table
        INSERT INTO externalDWH.Inventory (ProductID, ProductName, StockLevel, ReorderLevel, SupplierID)
        VALUES 
        (1001, 'Product A', 50, 10, 201),
        (1002, 'Product B', 20, 5, 202);

        -- Insert sample data into Sale table
        INSERT INTO externalDWH.Sale (SaleID, RegionID, StoreID, ProductID, Quantity, TotalAmount, SalesDate, CustomerID)
        VALUES 
        (1, 1, 101, 1001, 2, 39.98, '2025-01-01', 1),
        (2, 2, 102, 1002, 1, 9.99, '2025-01-01', 2);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END
GO