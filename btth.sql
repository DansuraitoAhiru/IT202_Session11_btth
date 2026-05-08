CREATE DATABASE RikkeiClinicDB;
USE RikkeiClinicDB;

CREATE TABLE Medicines (
    medicine_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

CREATE TABLE Patient_Invoices (
    patient_id INT PRIMARY KEY,
    total_due DECIMAL(18,2) NOT NULL DEFAULT 0
);

INSERT INTO Medicines (medicine_id, name, price, stock) 
VALUES
	(1, 'Amoxicillin 500mg', 15000, 100),  -- Tồn kho nhiều
	(2, 'Panadol Extra', 5000, 5);         -- Tồn kho ít

INSERT INTO Patient_Invoices (patient_id, total_due) 
VALUES
	(1, 1500000.00), -- Đã sửa: Nợ 1.5tr để test bài Giải phóng giường bệnh
	(2, 0),
	(3, 0);
    
-- Phần A
-- dữ liệu đầu vào: p_patient_id → mã bệnh nhân, p_medicine_id → mã thuốc, p_quantity → số lượng kê, p_discount_code → mã giảm giá
-- dữ liệu đầu ra: 1 cái thông báo, đặt là p_message

-- Luồng:
-- Lấy: stock (tồn kho) và price (đơn giá)
-- So sánh: Nếu p_quantity > stock thì Lỗi, trả về thông báo thất bại
-- Nếu đủ hàng: Trừ kho và Tính tiền: total = quantity * price
-- Áp dụng giảm giá: Nếu mã là NV-RIKKEI thì giảm 50%
-- Ngược lại thì giữ nguyên
-- Cập nhật:
-- cộng lại vào Patient_Invoices.total_due
-- nếu đã thực hiện xong tất cả, trả về tb: "Thành công: Đã xử lý đơn thuốc"

-- Các biến cục bộ sẽ dùng:
-- v_stock → số lượng tồn kho vì cần phải so sánh trước khi trừ kho
-- v_price → đơn giá vì cần dùng để tính tiền và để ko bị lặp query
-- v_total → tiền gốc vì còn phần giá sau khi áp mã giảm giá nữa nên để rõ ràng, tạo 1 biên lưu trữ giá trước giảm
-- v_discount_price → tiền sau giảm giá vì như đã nói trên cần giá tiền sẽ có 2 trạng thái: trước & sau giảm và không nên ghi đè luôn v_total (dễ rối logic, nhỡ đâu còn phải dùng giá gốc cho việc khác)

delimiter //
create procedure ProcessPrescription (
	in p_quantity int,
    in p_medicine_id int,
    in p_patient_id int,
    in p_discount_code varchar(10),
    out p_message varchar(100)
)
begin
	declare v_stock int;
    declare v_price DECIMAL(18,2);
    declare v_total_price decimal(18, 2);
    declare v_discount_price decimal(18, 2);
    
    select stock, price into v_stock, v_price from Medicines
    where medicine_id = p_medicine_id;
    
    if p_quantity > v_stock then 
		set p_message =  'Thất bại: Kho không đủ thuốc';
	else
		update Medicines
		set stock = stock - p_quantity
        where medicine_id = p_medicine_id;
        
        set v_total_price = p_quantity * v_price;
        
        if p_discount_code = 'NV-RIKKEI' then
			set v_discount_price = v_total_price * 0.5;
		else 
			set v_discount_price = v_total_price;
		end if;
        
        update Patient_Invoices
        set total_due = total_due + v_discount_price
        where patient_id = p_patient_id;
        
        set p_message = 'Thành công: Đã xử lý đơn thuốc';
	end if;
end //
delimiter ;

call ProcessPrescription (10, 1, 3, null, @message);
select @message;

call ProcessPrescription (10, 1, 1, 'NV-RIKKEI', @message);
select @message;
select * from Patient_Invoices where patient_id = 1;

call ProcessPrescription (10, 2, 2, 'NV-RIKKEI', @message);
select @message;
