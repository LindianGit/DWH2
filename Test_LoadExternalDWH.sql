USE externalDB2;
GO

/*
    Script: Validate and Populate Sales Data
    Author: Lindian Carlos
    Created Date: 2025-01-02

    Description:
    This script performs the following tasks:
    1. Drops temporary tables if they exist.
    2. Calculates actual sales per customer and stores the results in a temporary table.
    3. Inserts expected sales per customer into another temporary table.
    4. Validates the actual sales per customer against the expected results.
    5. Calculates actual sales per region and stores the results in a temporary table.
    6. Inserts expected sales per region into another temporary table.
    7. Validates the actual sales per region against the expected results.
    8. Ensures that the main tables are populated by checking the record counts.
    9. Drops the temporary tables at the end.

    Usage:
    Execute this script to validate sales data and ensure the main tables are populated correctly.
*/

-- Drop temporary tables if they exist
IF OBJECT_ID('tempdb..#ActualSalesPerCustomer', 'U') IS NOT NULL DROP TABLE #ActualSalesPerCustomer;
IF OBJECT_ID('tempdb..#ExpectedSalesPerCustomer', 'U') IS NOT NULL DROP TABLE #ExpectedSalesPerCustomer;
IF OBJECT_ID('tempdb..#ActualSalesPerRegion', 'U') IS NOT NULL DROP TABLE #ActualSalesPerRegion;
IF OBJECT_ID('tempdb..#ExpectedSalesPerRegion', 'U') IS NOT NULL DROP TABLE #ExpectedSalesPerRegion;
IF OBJECT_ID('tempdb..#TablePopulationCheck', 'U') IS NOT NULL DROP TABLE #TablePopulationCheck;
GO

-- Use a single BEGIN...END block to ensure the temporary tables are created and accessed within the same batch
BEGIN
    -- Calculate sales per customer
    SELECT 
        c.CustomerID,
        c.FirstName,
        c.LastName,
        SUM(s.TotalAmount) AS TotalSales
    INTO #ActualSalesPerCustomer
    FROM 
        externalDWH.Customer c
    JOIN 
        externalDWH.Sale s ON c.CustomerID = s.CustomerID
    GROUP BY 
        c.CustomerID, c.FirstName, c.LastName;

    -- Insert expected results into a temporary table
    CREATE TABLE #ExpectedSalesPerCustomer (
        CustomerID INT,
        FirstName NVARCHAR(50),
        LastName NVARCHAR(50),
        TotalSales DECIMAL(10, 2)
    );

    INSERT INTO #ExpectedSalesPerCustomer (CustomerID, FirstName, LastName, TotalSales)
    VALUES 
    (1, 'John', 'Doe', 39.98),
    (2, 'Jane', 'Smith', 9.99);

    -- Validate the results for sales per customer
    SELECT 
        a.CustomerID,
        a.FirstName,
        a.LastName,
        a.TotalSales,
        e.TotalSales AS ExpectedTotalSales,
        CASE 
            WHEN a.TotalSales = e.TotalSales THEN 'PASS'
            ELSE 'FAIL'
        END AS TestResult
    FROM 
        #ActualSalesPerCustomer a
    LEFT JOIN 
        #ExpectedSalesPerCustomer e ON a.CustomerID = e.CustomerID;

    -- Calculate sales per region
    SELECT 
        r.RegionID,
        r.RegionName,
        SUM(s.TotalAmount) AS TotalSales
    INTO #ActualSalesPerRegion
    FROM 
        externalDWH.Sale s
    JOIN 
        externalDWH.Region r ON s.RegionID = r.RegionID
    GROUP BY 
        r.RegionID, r.RegionName;

    -- Insert expected results into a temporary table
    CREATE TABLE #ExpectedSalesPerRegion (
        RegionID INT,
        RegionName NVARCHAR(100),
        TotalSales DECIMAL(10, 2)
    );

    INSERT INTO #ExpectedSalesPerRegion (RegionID, RegionName, TotalSales)
    VALUES 
    (1, 'North America', 39.98),
    (2, 'Europe', 9.99);

    -- Validate the results for sales per region
    SELECT 
        a.RegionID,
        a.RegionName,
        a.TotalSales,
        e.TotalSales AS ExpectedTotalSales,
        CASE 
            WHEN a.TotalSales = e.TotalSales THEN 'PASS'
            ELSE 'FAIL'
        END AS TestResult
    FROM 
        #ActualSalesPerRegion a
    LEFT JOIN 
        #ExpectedSalesPerRegion e ON a.RegionID = e.RegionID AND a.RegionName = e.RegionName;

    -- Ensure the tables are populated
    CREATE TABLE #TablePopulationCheck (
        TableName NVARCHAR(255),
        RecordCount INT
    );

    INSERT INTO #TablePopulationCheck (TableName, RecordCount)
    VALUES 
    ('Date', (SELECT COUNT(*) FROM externalDWH.Date)),
    ('Region', (SELECT COUNT(*) FROM externalDWH.Region)),
    ('Customer', (SELECT COUNT(*) FROM externalDWH.Customer)),
    ('Transactions', (SELECT COUNT(*) FROM externalDWH.Transactions)),
    ('Inventory', (SELECT COUNT(*) FROM externalDWH.Inventory)),
    ('Sale', (SELECT COUNT(*) FROM externalDWH.Sale));

    -- Validate table population
    SELECT 
        TableName,
        RecordCount,
        CASE 
            WHEN RecordCount > 0 THEN 'PASS'
            ELSE 'FAIL'
        END AS TestResult
    FROM 
        #TablePopulationCheck;

    -- Drop temporary tables
    IF OBJECT_ID('tempdb..#ActualSalesPerCustomer', 'U') IS NOT NULL DROP TABLE #ActualSalesPerCustomer;
    IF OBJECT_ID('tempdb..#ExpectedSalesPerCustomer', 'U') IS NOT NULL DROP TABLE #ExpectedSalesPerCustomer;
    IF OBJECT_ID('tempdb..#ActualSalesPerRegion', 'U') IS NOT NULL DROP TABLE #ActualSalesPerRegion;
    IF OBJECT_ID('tempdb..#ExpectedSalesPerRegion', 'U') IS NOT NULL DROP TABLE #ExpectedSalesPerRegion;
    IF OBJECT_ID('tempdb..#TablePopulationCheck', 'U') IS NOT NULL DROP TABLE #TablePopulationCheck;
END
GO