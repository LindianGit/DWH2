USE externalDB2;
GO

-- Drop the stored procedure if it already exists
IF OBJECT_ID('dbo.SetupExternalDWH', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.SetupExternalDWH;
END
GO

/*
    Stored Procedure: SetupExternalDWH
    Author: Lindian Carlos
    Created Date: 2025-01-02

    Description:
    This stored procedure is designed to create and populate the schema for the externalDWH database.
    It performs the following tasks:
    1. Creates the externalDWH schema if it does not already exist.
    2. Drops existing foreign key constraints on the Customer and Sale tables, if any.
    3. Drops existing tables in the correct order to avoid foreign key violations.
    4. Creates the Date, Region, Customer, Transactions, Inventory, and Sale tables with the necessary columns and constraints.

    Usage:
    To create and populate the schema, simply execute the stored procedure:
    EXEC dbo.SetupExternalDWH;
*/

-- Create stored procedure to create and populate schema
CREATE PROCEDURE dbo.SetupExternalDWH
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Create schema if it doesn't exist
        IF NOT EXISTS (SELECT schema_name
                       FROM information_schema.schemata
                       WHERE schema_name = 'externalDWH')
        BEGIN
            EXEC('CREATE SCHEMA externalDWH');
        END

        -- Drop foreign key constraints if they exist
        IF EXISTS (SELECT * FROM information_schema.table_constraints
                   WHERE constraint_type = 'FOREIGN KEY' 
                     AND table_name = 'Customer' 
                     AND table_schema = 'externalDWH')
        BEGIN
            DECLARE @constraint_name NVARCHAR(255);
            SELECT @constraint_name = constraint_name
            FROM information_schema.table_constraints
            WHERE constraint_type = 'FOREIGN KEY' 
              AND table_name = 'Customer' 
              AND table_schema = 'externalDWH';
            EXEC('ALTER TABLE externalDWH.Customer DROP CONSTRAINT ' + @constraint_name);
        END
        
        IF EXISTS (SELECT * FROM information_schema.table_constraints
                   WHERE constraint_type = 'FOREIGN KEY' 
                     AND table_name = 'Sale' 
                     AND table_schema = 'externalDWH')
        BEGIN
            SELECT @constraint_name = constraint_name
            FROM information_schema.table_constraints
            WHERE constraint_type = 'FOREIGN KEY' 
              AND table_name = 'Sale' 
              AND table_schema = 'externalDWH';
            EXEC('ALTER TABLE externalDWH.Sale DROP CONSTRAINT ' + @constraint_name);
        END

        -- Drop tables if they already exist in the correct order to avoid foreign key violations
        IF EXISTS (SELECT * FROM information_schema.tables 
                   WHERE table_name = 'Sale' 
                     AND table_schema = 'externalDWH')
        BEGIN
            DROP TABLE externalDWH.Sale;
        END

        IF EXISTS (SELECT * FROM information_schema.tables 
                   WHERE table_name = 'Transactions' 
                     AND table_schema = 'externalDWH')
        BEGIN
            DROP TABLE externalDWH.Transactions;
        END

        IF EXISTS (SELECT * FROM information_schema.tables 
                   WHERE table_name = 'Inventory' 
                     AND table_schema = 'externalDWH')
        BEGIN
            DROP TABLE externalDWH.Inventory;
        END

        IF EXISTS (SELECT * FROM information_schema.tables 
                   WHERE table_name = 'Customer' 
                     AND table_schema = 'externalDWH')
        BEGIN
            DROP TABLE externalDWH.Customer;
        END

        IF EXISTS (SELECT * FROM information_schema.tables 
                   WHERE table_name = 'Date' 
                     AND table_schema = 'externalDWH')
        BEGIN
            DROP TABLE externalDWH.Date;
        END

        IF EXISTS (SELECT * FROM information_schema.tables 
                   WHERE table_name = 'Region' 
                     AND table_schema = 'externalDWH')
        BEGIN
            DROP TABLE externalDWH.Region;
        END

        -- Create Date table
        CREATE TABLE externalDWH.Date (
            DateKey INT PRIMARY KEY,
            Date DATE NOT NULL,
            Year INT NOT NULL,
            Quarter INT NOT NULL,
            Month INT NOT NULL,
            Day INT NOT NULL,
            Week INT NOT NULL,
            DayOfWeek INT NOT NULL,
            IsWeekend BIT NOT NULL,
            CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            CreatedBy NVARCHAR(50) DEFAULT CURRENT_USER,
            UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            UpdatedBy NVARCHAR(50) DEFAULT CURRENT_USER
        );

        -- Create Region table
        CREATE TABLE externalDWH.Region (
            RegionID INT PRIMARY KEY,
            RegionName NVARCHAR(100) NOT NULL,
            CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            CreatedBy NVARCHAR(50) DEFAULT CURRENT_USER,
            UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            UpdatedBy NVARCHAR(50) DEFAULT CURRENT_USER
        );

        -- Create Customer table
        CREATE TABLE externalDWH.Customer (
            CustomerID INT PRIMARY KEY,
            FirstName NVARCHAR(50) NOT NULL,
            LastName NVARCHAR(50) NOT NULL,
            Email NVARCHAR(100) NOT NULL,
            Phone NVARCHAR(20) NULL,
            JoinDate DATETIME NOT NULL,
            RegionID INT NOT NULL,
            CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            CreatedBy NVARCHAR(50) DEFAULT CURRENT_USER,
            UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            UpdatedBy NVARCHAR(50) DEFAULT CURRENT_USER,
            CONSTRAINT FK_Customer_Region FOREIGN KEY (RegionID) REFERENCES externalDWH.Region(RegionID)
        );

        -- Create Transactions table
        CREATE TABLE externalDWH.Transactions (
            TransactionID INT PRIMARY KEY,
            StoreID INT NOT NULL,
            ProductID INT NOT NULL,
            Quantity INT NOT NULL,
            Price DECIMAL(10, 2) NOT NULL,
            Timestamp DATETIME NOT NULL,
            CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            CreatedBy NVARCHAR(50) DEFAULT CURRENT_USER,
            UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            UpdatedBy NVARCHAR(50) DEFAULT CURRENT_USER
        );

        -- Create Inventory table
        CREATE TABLE externalDWH.Inventory (
            ProductID INT PRIMARY KEY,
            ProductName NVARCHAR(100) NOT NULL,
            StockLevel INT NOT NULL,
            ReorderLevel INT NOT NULL,
            SupplierID INT NOT NULL,
            CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            CreatedBy NVARCHAR(50) DEFAULT CURRENT_USER,
            UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            UpdatedBy NVARCHAR(50) DEFAULT CURRENT_USER
        );

        -- Create Sale table
        CREATE TABLE externalDWH.Sale (
            SaleID INT PRIMARY KEY,
            RegionID INT NOT NULL,
            StoreID INT NOT NULL,
            ProductID INT NOT NULL,
            Quantity INT NOT NULL,
            TotalAmount DECIMAL(10, 2) NOT NULL,
            SalesDate DATE NOT NULL,
            CustomerID INT NOT NULL,
            CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            CreatedBy NVARCHAR(50) DEFAULT CURRENT_USER,
            UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            UpdatedBy NVARCHAR(50) DEFAULT CURRENT_USER,
            CONSTRAINT FK_Sale_Region FOREIGN KEY (RegionID) REFERENCES externalDWH.Region(RegionID),
            CONSTRAINT FK_Sale_Customer FOREIGN KEY (CustomerID) REFERENCES externalDWH.Customer(CustomerID)
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END
GO