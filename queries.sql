-- ex1


ALTER TABLE suppliers
ADD COLUMN balance DECIMAL(10,2) DEFAULT 0.00;


-- ex2


CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    payment_date DATETIME NOT NULL,
    supplier_id INT,
    pay_sum DECIMAL(10, 2) NOT NULL,
    description VARCHAR(255),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);


--ex3


UPDATE suppliers s
SET s.balance = (
    -- Считаем общую сумму выплат поставщику
    (SELECT IFNULL(SUM(p.amount), 0)
     FROM payments p
     WHERE p.supplier_id = s.id)
    - 
    -- Считаем общую сумму поставок от поставщика
    (SELECT IFNULL(SUM(a.qty * a.price), 0)
     FROM actions a
     WHERE a.supplier_id = s.id)
);


--ex4


START TRANSACTION;

-- Добавляем новый платеж в таблицу payments
INSERT INTO payments (supplier_id, payment_date, amount)
VALUES (@supplier_id, NOW(), @payment_amount);

-- Пересчитываем баланс поставщика
UPDATE suppliers s
SET s.balance = (
    -- Считаем новую общую сумму выплат поставщику (включая новый платеж)
    (SELECT IFNULL(SUM(p.amount), 0)
     FROM payments p
     WHERE p.supplier_id = s.id)
    - 
    -- Считаем общую сумму поставок от поставщика
    (SELECT IFNULL(SUM(a.qty * a.price), 0)
     FROM actions a
     WHERE a.supplier_id = s.id)
)
WHERE s.id = @supplier_id;

COMMIT;


--ex5

START TRANSACTION;

-- Устанавливаем переменные
SET @date = '2017-03-14 11:00:00';
SET @product = 24;
SET @supplier = 2;
SET @qty = 14;
SET @price = 161;

-- Добавляем новую запись в таблицу поставок (actions)
INSERT INTO actions (action_date, product_id, supplier_id, qty, price) 
VALUES (@date, @product, @supplier, @qty, @price);

-- Обновляем общую сумму поставок (income_sum)
UPDATE suppliers 
SET income_sum = income_sum + (@qty * @price) 
WHERE id = @supplier;

-- Пересчитываем баланс поставщика
UPDATE suppliers s
SET s.balance = (
    -- Считаем общую сумму выплат поставщику
    (SELECT IFNULL(SUM(p.amount), 0)
     FROM payments p
     WHERE p.supplier_id = s.id)
    - 
    -- Считаем общую сумму поставок (включая новую поставку)
    (SELECT IFNULL(SUM(a.qty * a.price), 0)
     FROM actions a
     WHERE a.supplier_id = s.id)
)
WHERE s.id = @supplier;

-- Завершаем транзакцию
COMMIT;


