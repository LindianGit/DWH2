USE externalDB2
GO

-- Create schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'externalDWH')
BEGIN
    EXEC('CREATE SCHEMA externalDWH');
END
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -- Drop foreign key constraints if they exist
    IF OBJECT_ID('externalDWH.Customer', 'U') IS NOT NULL
    BEGIN
        DECLARE @constraint_name NVARCHAR(255)
        SELECT @constraint_name = name
        FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID('externalDWH.Customer') AND referenced_object_id = OBJECT_ID('externalDWH.Region')
        IF @constraint_name IS NOT NULL
            EXEC('ALTER TABLE externalDWH.Customer DROP CONSTRAINT ' + @constraint_name)
    END

    IF OBJECT_ID('externalDWH.Sale', 'U') IS NOT NULL
    BEGIN
        SELECT @constraint_name = name
        FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID('externalDWH.Sale') AND referenced_object_id = OBJECT_ID('externalDWH.Region')
        IF @constraint_name IS NOT NULL
            EXEC('ALTER TABLE externalDWH.Sale DROP CONSTRAINT ' + @constraint_name)
    END

    -- Drop tables if they already exist
    IF OBJECT_ID('externalDWH.Date', 'U') IS NOT NULL DROP TABLE externalDWH.Date;
    IF OBJECT_ID('externalDWH.Region', 'U') IS NOT NULL DROP TABLE externalDWH.Region;
    IF OBJECT_ID('externalDWH.Customer', 'U') IS NOT NULL DROP TABLE externalDWH.Customer;
    IF OBJECT_ID('externalDWH.Transactions', 'U') IS NOT NULL DROP TABLE externalDWH.Transactions;
    IF OBJECT_ID('externalDWH.Inventory', 'U') IS NOT NULL DROP TABLE externalDWH.Inventory;
    IF OBJECT_ID('externalDWH.Sale', 'U') IS NOT NULL DROP TABLE externalDWH.Sale;

    -- Create Date table
    -- This table stores date-related information, including various date components and a flag for weekends.
    CREATE TABLE externalDWH.Date (
        DateKey INT PRIMARY KEY,                             -- Unique key for each date
        Date DATE NOT NULL,                                  -- Actual date
        Year INT NOT NULL,                                   -- Year part of the date
        Quarter INT NOT NULL,                                -- Quarter part of the date
        Month INT NOT NULL,                                  -- Month part of the date
        Day INT NOT NULL,                                    -- Day part of the date
        Week INT NOT NULL,                                   -- Week number of the year
        DayOfWeek INT NOT NULL,                              -- Day of the week (1=Sunday, 7=Saturday)
        IsWeekend BIT NOT NULL,                              -- Flag to indicate if the date is a weekend (1 for true, 0 for false)
        CreatedAt DATETIME DEFAULT GETDATE(),                -- Timestamp of record creation
        CreatedBy NVARCHAR(50) DEFAULT SYSTEM_USER,          -- User who created the record
        UpdatedAt DATETIME DEFAULT GETDATE(),                -- Timestamp of last update
        UpdatedBy NVARCHAR(50) DEFAULT SYSTEM_USER           -- User who last updated the record
    );

    -- Create Region table
    -- This table stores information about different regions.
    CREATE TABLE externalDWH.Region (
        RegionID INT PRIMARY KEY,                            -- Unique identifier for each region
        RegionName NVARCHAR(100) NOT NULL,                   -- Name of the region
        CreatedAt DATETIME DEFAULT GETDATE(),                -- Timestamp of record creation
        CreatedBy NVARCHAR(50) DEFAULT SYSTEM_USER,          -- User who created the record
        UpdatedAt DATETIME DEFAULT GETDATE(),                -- Timestamp of last update
        UpdatedBy NVARCHAR(50) DEFAULT SYSTEM_USER           -- User who last updated the record
    );

    -- Create Customer table
    -- This table stores information about customers.
    CREATE TABLE externalDWH.Customer (
        CustomerID INT PRIMARY KEY,                          -- Unique identifier for each customer
        FirstName NVARCHAR(50) NOT NULL,                     -- Customer's first name
        LastName NVARCHAR(50) NOT NULL,                      -- Customer's last name
        Email NVARCHAR(100) NOT NULL,                        -- Customer's email address
        Phone NVARCHAR(20) NULL,                             -- Customer's phone number (optional)
        JoinDate DATETIME NOT NULL,                          -- Date when the customer joined
        RegionID INT NOT NULL,                               -- Foreign key to the Region table
        CreatedAt DATETIME DEFAULT GETDATE(),                -- Timestamp of record creation
        CreatedBy NVARCHAR(50) DEFAULT SYSTEM_USER,          -- User who created the record
        UpdatedAt DATETIME DEFAULT GETDATE(),                -- Timestamp of last update
        UpdatedBy NVARCHAR(50) DEFAULT SYSTEM_USER,          -- User who last updated the record,
        CONSTRAINT FK_Customer_Region FOREIGN KEY (RegionID) REFERENCES externalDWH.Region(RegionID) -- Foreign key constraint to ensure RegionID exists in the Region table
    );

    -- Create Transactions table
    -- This table stores information about transactions.
    CREATE TABLE externalDWH.Transactions (
        TransactionID INT PRIMARY KEY,                       -- Unique identifier for each transaction
        StoreID INT NOT NULL,                                -- Identifier for the store where the transaction occurred
        ProductID INT NOT NULL,                              -- Identifier for the product involved in the transaction
        Quantity INT NOT NULL,                               -- Quantity of the product in the transaction
        Price DECIMAL(10, 2) NOT NULL,                       -- Price of the product
        Timestamp DATETIME NOT NULL,                         -- Date and time when the transaction occurred
        CreatedAt DATETIME DEFAULT GETDATE(),                -- Timestamp of record creation
        CreatedBy NVARCHAR(50) DEFAULT SYSTEM_USER,          -- User who created the record
        UpdatedAt DATETIME DEFAULT GETDATE(),                -- Timestamp of last update
        UpdatedBy NVARCHAR(50) DEFAULT SYSTEM_USER           -- User who last updated the record
    );

    -- Create Inventory table
    -- This table stores information about product inventory.
    CREATE TABLE externalDWH.Inventory (
        ProductID INT PRIMARY KEY,                           -- Unique identifier for each product
        ProductName NVARCHAR(100) NOT NULL,                  -- Name of the product
        StockLevel INT NOT NULL,                             -- Current stock level of the product
        ReorderLevel INT NOT NULL,                           -- Stock level at which the product should be reordered
        SupplierID INT NOT NULL,                             -- Identifier for the supplier of the product
        CreatedAt DATETIME DEFAULT GETDATE(),                -- Timestamp of record creation
        CreatedBy NVARCHAR(50) DEFAULT SYSTEM_USER,          -- User who created the record
        UpdatedAt DATETIME DEFAULT GETDATE(),                -- Timestamp of last update
        UpdatedBy NVARCHAR(50) DEFAULT SYSTEM_USER           -- User who last updated the record
    );

    -- Create Sale table
    -- This table stores information about product sales.
    CREATE TABLE externalDWH.Sale (
        SaleID INT PRIMARY KEY,                              -- Unique identifier for each sale
        RegionID INT NOT NULL,                               -- Foreign key to the Region table
        StoreID INT NOT NULL,                                -- Identifier for the store where the sale occurred
        ProductID INT NOT NULL,                              -- Identifier for the product sold
        Quantity INT NOT NULL,                               -- Quantity of the product sold
        TotalAmount DECIMAL(10, 2) NOT NULL,                 -- Total amount of the sale
        SalesDate DATE NOT NULL,                             -- Date of the sale
        CreatedAt DATETIME DEFAULT GETDATE(),                -- Timestamp of record creation
        CreatedBy NVARCHAR(50) DEFAULT SYSTEM_USER,          -- User who created the record
        UpdatedAt DATETIME DEFAULT GETDATE(),                -- Timestamp of last update
        UpdatedBy NVARCHAR(50) DEFAULT SYSTEM_USER,          -- User who last updated the record,
        CONSTRAINT FK_Sale_Region FOREIGN KEY (RegionID) REFERENCES externalDWH.Region(RegionID) -- Foreign key constraint to ensure RegionID exists in the Region table
    );

    -- Indexes to improve performance
    -- These indexes are created on foreign key columns and commonly queried columns to speed up data retrieval operations.
    CREATE INDEX IX_Customer_RegionID ON externalDWH.Customer(RegionID);             -- Index on RegionID in Customer table
    CREATE INDEX IX_Transaction_ProductID ON externalDWH.Transactions(ProductID);    -- Index on ProductID in Transaction table
    CREATE INDEX IX_Transaction_StoreID ON externalDWH.Transactions(StoreID);        -- Index on StoreID in Transaction table
    CREATE INDEX IX_Inventory_SupplierID ON externalDWH.Inventory(SupplierID);       -- Index on SupplierID in Inventory table
    CREATE INDEX IX_Sale_RegionID ON externalDWH.Sale(RegionID);                     -- Index on RegionID in Sale table
    CREATE INDEX IX_Sale_ProductID ON externalDWH.Sale(ProductID);                   -- Index on ProductID in Sale table
    CREATE INDEX IX_Sale_StoreID ON externalDWH.Sale(StoreID);                       -- Index on StoreID in Sale table

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
END CATCH;