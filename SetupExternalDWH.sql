USE internalDB2;
GO

-- Drop the stored procedure if it already exists
IF OBJECT_ID('dbo.SetupexternalDWH', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.SetupexternalDWH;
END
GO

/*
    Stored Procedure: SetupexternalDWH
    Author: Lindian Carlos
    Created Date: 2025-01-02

    Description:
    This stored procedure is designed to create and populate the schema for the Staging area of the internalDB2 database.
    It performs the following tasks:
    1. Creates the Staging schema if it does not already exist.
    2. Drops existing tables in the correct order.
    3. Creates the Date, Region, Customer, Transactions, Inventory, and Sale tables with the necessary columns.

    Usage:
    To create and populate the schema, simply execute the stored procedure:
    EXEC dbo.SetupexternalDWH;
*/

-- Create stored procedure to create and populate schema


CREATE PROCEDURE dbo.SetupexternalDWH
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Create schema if it doesn't exist
        IF NOT EXISTS (SELECT schema_name
                       FROM information_schema.schemata
                       WHERE schema_name = 'Staging')
        BEGIN
            EXEC('CREATE SCHEMA Staging');
        END

        -- Drop tables if they already exist in the correct order
        IF EXISTS (SELECT * FROM information_schema.tables 
                   WHERE table_name = 'Sale' 
                     AND table_schema = 'Staging')
        BEGIN
            DROP TABLE Staging.Sale;
        END

        IF EXISTS (SELECT * FROM information_schema.tables 
                   WHERE table_name = 'Transactions' 
                     AND table_schema = 'Staging')
        BEGIN
            DROP TABLE Staging.Transactions;
        END

        IF EXISTS (SELECT * FROM information_schema.tables 
                   WHERE table_name = 'Inventory' 
                     AND table_schema = 'Staging')
        BEGIN
            DROP TABLE Staging.Inventory;
        END

        IF EXISTS (SELECT * FROM information_schema.tables 
                   WHERE table_name = 'Customer' 
                     AND table_schema = 'Staging')
        BEGIN
            DROP TABLE Staging.Customer;
        END

        IF EXISTS (SELECT * FROM information_schema.tables 
                   WHERE table_name = 'Date' 
                     AND table_schema = 'Staging')
        BEGIN
            DROP TABLE Staging.Date;
        END

        IF EXISTS (SELECT * FROM information_schema.tables 
                   WHERE table_name = 'Region' 
                     AND table_schema = 'Staging')
        BEGIN
            DROP TABLE Staging.Region;
        END

        -- Create Date table
        CREATE TABLE Staging.Date (
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
        CREATE TABLE Staging.Region (
            RegionID INT PRIMARY KEY,
            RegionName NVARCHAR(100) NOT NULL,
            CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            CreatedBy NVARCHAR(50) DEFAULT CURRENT_USER,
            UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            UpdatedBy NVARCHAR(50) DEFAULT CURRENT_USER
        );

        -- Create Customer table
        CREATE TABLE Staging.Customer (
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
            UpdatedBy NVARCHAR(50) DEFAULT CURRENT_USER
        );

        -- Create Transactions table
        CREATE TABLE Staging.Transactions (
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
        CREATE TABLE Staging.Inventory (
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
        CREATE TABLE Staging.Sale (
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
            UpdatedBy NVARCHAR(50) DEFAULT CURRENT_USER
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END
GO