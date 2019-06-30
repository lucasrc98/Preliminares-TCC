CREATE TABLE base_suja(

	base_data timestamp,	
	base_cidade varchar(255),
	base_endereco varchar(255),
	base_branco varchar(255),
	base_placa varchar(255),
	base_modelo varchar(255),
	base_cor varchar(255),
	base_estado varchar(255),
	base_dezena varchar(255),
	base_unidade varchar(255),
	base_situacao varchar(255),
	base_ais varchar(255),
	base_cidadex varchar(255),
	base_tipovia varchar(255),		
	base_local_referencia varchar(255)		

);CREATE TABLE sensores_sujo(

	sensor_id int,
	sensor_id_2 int,
	sensor_endereco varchar(255),
	sensor_cidade varchar(255),
	sensor_tipovia varchar(255),
	sensor_local_referencia varchar(255),
	sensor_latitude float,
	sensor_longitude float

);

------------	Criando tabela	---------------------
CREATE TABLE base_limpa
(
  base_data TIMESTAMP
, base_cidade VARCHAR(255)
, base_endereco VARCHAR(255)
, base_placa VARCHAR(255)
, base_modelo VARCHAR(255)
, base_cor VARCHAR(255)
, base_tipovia VARCHAR(255)
, base_local_referencia VARCHAR(255)
)
;
----------------------------

----	populando	----
INSERT INTO base_limpa ( base_data, base_cidade,
 base_endereco,base_placa, base_modelo, base_cor,
  base_tipovia,base_local_referencia)
SELECT distinct 
	base_data,
	base_cidade,
	base_endereco,
	base_placa,
	base_modelo,
	base_cor,
	base_tipovia,
	base_local_referencia FROM base_suja
WHERE base_cidade = 'FORTALEZA' AND base_data::timestamp < '2017-09-02 00:00:00'::timestamp
ORDER BY base_data;


-----	Criando tabela	----
CREATE TABLE sensores_limpo
(
  sensor_id INTEGER
, sensor_endereco VARCHAR(255)
, sensor_cidade VARCHAR(255)
, sensor_tipovia VARCHAR(255)
, sensor_local_referencia VARCHAR(255)
, sensor_latitude DOUBLE PRECISION
, sensor_longitude DOUBLE PRECISION
)
;
---------------------
---	Populando	-----

INSERT INTO sensores_limpo (sensor_id, sensor_endereco,
sensor_cidade, sensor_tipovia, sensor_local_referencia,
sensor_latitude,sensor_longitude)
SELECT DISTINCT sensor_id, sensor_endereco, sensor_cidade,
sensor_tipovia, sensor_local_referencia, sensor_latitude,
sensor_longitude
FROM sensores_sujo WHERE sensor_cidade = 'FORTALEZA';

-------------------------------------------

-----	CRIANDO TABELA tabela_master	--------------------------------------

CREATE TABLE tabela_master(
	id_master serial NOT NULL,
	base_data "timestamp",	
	base_cidade varchar(255),
	base_endereco varchar(255),
	base_placa varchar(255),
	base_modelo varchar(255),
	base_cor varchar(255),
	base_tipovia varchar(255),		
	base_local_referencia varchar(255),	

	sensor_id int,
	sensor_endereco varchar(255),
	sensor_cidade varchar(255),
	sensor_tipovia varchar(255),
	sensor_local_referencia varchar(255),
	sensor_latitude float,
	sensor_longitude float
)
;

-----	POPULANDO tabela_master	----------
INSERT INTO tabela_master ( base_data, base_cidade,
	base_endereco,
	base_placa,
	base_modelo,
	base_cor,
	base_tipovia,		
	base_local_referencia,
	sensor_id,
	sensor_endereco,
	sensor_cidade,
	sensor_tipovia,
	sensor_local_referencia,
	sensor_latitude,
	sensor_longitude	)
SELECT distinct *
FROM base_limpa b, sensores_limpo s 
WHERE b.base_endereco = s.sensor_endereco AND
b.base_local_referencia = s.sensor_local_referencia order by b.base_data;

-----------------------------------------------------------------------------------

-----	CRIANDO TABELA dim_sensor	--------------------------------------
CREATE TABLE dim_sensor ( 
	sk_sensor serial NOT NULL PRIMARY KEY,
	id_sensor int,
	endereco varchar(255),
	local_referencia varchar(255),
	latitude double precision,
	longitude double precision,
	cidade varchar(255),
	tipovia varchar(5)
);




-----	POPULANDO dim_sensor	-------

INSERT INTO dim_sensor ( 
	id_sensor,
	endereco,
	local_referencia,
	latitude,
	longitude,
	cidade,
	tipovia)
SELECT distinct b.sensor_id, b.sensor_endereco, b.sensor_local_referencia,
b.sensor_latitude, b.sensor_longitude, b.base_cidade, s.sensor_tipovia
from tabela_master b, sensores_limpo s 
where s.sensor_endereco = b.base_endereco
and s.sensor_local_referencia = b.base_local_referencia
and s.sensor_cidade = b.base_cidade
order by b.sensor_id;

------------------------------------------------------------------------------
---	CRIANDO TABELA dim_veiculo	-------------------------------
CREATE TABLE dim_veiculo(
	sk_veiculo serial NOT NULL PRIMARY KEY,
	placa varchar(255),
	modelo varchar(255),
	cor varchar(255)
);

-----	POPULANDO TABELA dim_veiculo	--------------

INSERT INTO dim_veiculo(
	placa ,
	modelo )
SELECT distinct b.base_placa, b.base_modelo
FROM tabela_master b, sensores_limpo s WHERE b.base_placa != '' 
AND s.sensor_endereco = b.base_endereco
AND s.sensor_local_referencia = b.base_local_referencia
AND s.sensor_cidade = b.base_cidade 
order by b.base_placa;

----------------------------------------------------------------------------------


---	CRIANDO TABELA dim_tempo	-------------------------------
CREATE TABLE dim_tempo(
	sk_tempo serial NOT NULL PRIMARY KEY,
	"data" TIMESTAMP,
	ano DOUBLE PRECISION,
	mes DOUBLE PRECISION,
	dia DOUBLE PRECISION,
	hora DOUBLE PRECISION
	
);

-----	POPULANDO TABELA dim_tempo	--------------

INSERT INTO dim_tempo(
	"data" ,
	ano ,
	mes ,
	dia,
	hora)

SELECT distinct b.base_data,
EXTRACT(YEAR FROM b.base_data) AS ANO,
EXTRACT(MONTH FROM b.base_data) AS MES, 
EXTRACT(DAY FROM b.base_data) AS DIA,
EXTRACT(HOUR FROM b.base_data) AS HORA
FROM tabela_master b WHERE b.base_placa != '' 
AND b.sensor_endereco = b.base_endereco
AND b.sensor_local_referencia = b.base_local_referencia
AND b.sensor_cidade = b.base_cidade  order by b.base_data;

----------------------------------------------------------------------------------


----	CRIANDO TABELA fato	-----

CREATE TABLE fato(
	id_fato serial NOT NULL PRIMARY KEY,
	sk_veiculo INT,
	sk_tempo INT,
	sk_sensor INT,
	
	FOREIGN KEY (sk_veiculo) REFERENCES dim_veiculo (sk_veiculo),
	FOREIGN KEY (sk_tempo) REFERENCES dim_tempo (sk_tempo),
	FOREIGN KEY (sk_sensor) REFERENCES dim_sensor (sk_sensor)
);

----	POPULANDO TABELA fato	-----
INSERT INTO fato(
	sk_veiculo,
	sk_tempo,
	sk_sensor
)

SELECT distinct v.sk_veiculo, t.sk_tempo, s.sk_sensor
FROM dim_veiculo v, dim_tempo t, dim_sensor s, tabela_master b
WHERE b.sensor_id = s.id_sensor 
AND b.base_data = t."data"
AND b.base_placa = v.placa;

----------------------------------------------------------------------------------


------------------------------------------------------
--	colocar dia da semana na tabela dim_tempo	--

--	MOSTRAR O VEICULO QUE PASSOU EM N SENSORES ORDENADO PELO TEMPO	----


	SELECT  f.sk_veiculo, v.placa, t.data
	FROM fato f, dim_veiculo v, dim_tempo t
	where f.sk_veiculo = v.sk_veiculo
	and f.sk_tempo = t.sk_tempo
	order by f.sk_veiculo, f.sk_tempo;

-----------	quantidade de registros por mes	-----------------------------------


	select distinct t.mes, count(f.id_fato)Qtde_registros
	from fato f, dim_tempo t
	where f.sk_tempo = t.sk_tempo
	group by t.mes
	order by Qtde_registros DESC

----------	quantidade de registros por dia	-----------------------------------


	select distinct t.dia, count(f.id_fato)Qtde_registros
	from fato f, dim_tempo t
	where f.sk_tempo = t.sk_tempo
	group by t.dia
	order by Qtde_registros DESC



------------	quantidade de registros por hora	-----------------------------------

-- ORDENADO POR HORA

	select distinct t.hora, count(f.id_fato)Qtde_registros
	from fato f, dim_tempo t
	where f.sk_tempo = t.sk_tempo
	group by t.hora
	order by t.hora DESC


-- ORDENADO POR QUANTIDADE MAIOR DE REGISTROS

	select distinct t.hora, count(f.id_fato)Qtde_registros
	from fato f, dim_tempo t
	where f.sk_tempo = t.sk_tempo
	group by t.hora
	order by Qtde_registros DESC


-------------	quantidade de registro por mes e dia	------------------------------------------------

	select distinct t.mes, t.dia, count(f.id_fato)Qtde_registros
	from fato f, dim_tempo t
	where f.sk_tempo = t.sk_tempo
	group by t.mes, t.dia
	order by Qtde_registros DESC

-------------	quantidade de registro do mes, do dia por hora	------------------------------------------------

-- 	ordenado por quantidade

	select distinct t.mes, t.dia
	t.hora, count(f.id_fato)Qtde_registros
	from fato f, dim_tempo t
	where f.sk_tempo = t.sk_tempo
	group by t.mes, t.dia, t.hora
	order by Qtde_registros DESC

-- 	ordenado por data e hora

	select distinct t.mes, t.dia,
	t.hora, count(f.id_fato)Qtde_registros
	from fato f, dim_tempo t
	where f.sk_tempo = t.sk_tempo
	group by t.mes, t.dia, t.hora
	order by t.mes, t.dia, t.hora DESC



--	Quais foram os sensores pelos quais um veículo passou em
--      um determinado dia ordenados pelo tempo?	--
	
	SELECT  t.dia, s.id_sensor, s.latitude, longitude, v.placa
	FROM fato f, dim_veiculo v, dim_sensor s, dim_tempo t
	where f.sk_veiculo = v.sk_veiculo
	and f.sk_sensor = s.sk_sensor
	and f.sk_tempo = t.sk_tempo
	order by t.dia, f.sk_tempo;


-- •	Quantos veículos passaram por cada sensor no total?

	select distinct s.id_sensor,
	count(f.sk_sensor)Qtde_sensor
	from fato f, dim_sensor s
	where f.sk_sensor = s.sk_sensor
	group by s.sk_sensor
	order by Qtde_sensor DESC

--	•	Quantos veículos passaram por cada sensor no total em um determinado dia?

	select distinct t.dia, s.id_sensor,
	count(f.sk_sensor)Qtde_sensor
	from fato f, dim_sensor s, dim_tempo t
	where f.sk_sensor = s.sk_sensor
	and f.sk_tempo = t.sk_tempo
	group by t.dia, s.sk_sensor
	order by Qtde_sensor DESC


--	•	Quantos veículos passaram por cada sensor por hora de um determinada hora?


	select distinct s.id_sensor, t.hora, 
	count(f.sk_sensor)Qtde_sensor
	from fato f, dim_sensor s, dim_tempo t
	where f.sk_sensor = s.sk_sensor
	and f.sk_tempo = t.sk_tempo
	group by s.sk_sensor, t.hora
	order by s.id_sensor DESC




















--- Media de registros por sensor
select count(f.id_fato)Qtde_registros, count(f.sk_sensor)Qtde_sensor AVG(Qtde_registros, Qtde_sensor)
from dim_tempo t, dim_sensor s, fato f
where f.sk_tempo = t.sk_tempo
and s.sk_sensor = t.sk_sensor
---	Media por hora


---	Quantidade de registros por hora
	select distinct t.hora, count(f.id_fato)Qtde_registros
	from fato f, dim_tempo t
	where f.sk_tempo = t.sk_tempo
	group by t.hora
	order by Qtde_registros DESC

















select count(v.placa)Qtde_carros
	from dim_veiculo v
	group by v.placa
	order by Qtde_carros DESC



SELECT b.base_data,
EXTRACT(DAY FROM b.base_data) AS DIA,
EXTRACT(MONTH FROM b.base_data) AS MES, 
EXTRACT(YEAR FROM b.base_data) AS ANO
FROM tabela_master b WHERE b.base_placa != '' 
and b.base_cidade = 'FORTALEZA' order by b.base_data;


select id_master, base_data, base_placa, sensor_id, sensor_latitude, sensor_longitude 
from tabela_master order by base_placa, base_data;



SELECT distinct b.sensor_id, b.sensor_endereco, b.sensor_local_referencia, b.sensor_latitude, b.sensor_longitude
from tabela_master b, sensores_limpo s 
where s.sensor_endereco = b.base_endereco
and s.sensor_local_referencia = b.base_local_referencia
and s.sensor_cidade = 'FORTALEZA' 
and b.base_cidadex = 'FORTALEZA' order by b.sensor_id;



select distinct sensor_id from tabela_master



select distinct * from sensores_limpo order by sensores_limpo.sensor_id

select * from base_suja where base_cidade != base_cidadex

select * from base_suja b, sensores_sujo s where b.base_endereco = s.sensor_endereco AND b.base_local_referencia = s.sensor_local_referencia


SELECT * FROM "02_sensores_sujo" 
WHERE sensor_cidade = 'FORTALEZA'

select distinct * from "04_sensores_limpo"

SELECT distinct v.sk_veiculo, s.sk_sensor, t.sk_tempo , t.data
FROM dim_veiculo v, dim_tempo t, dim_sensor s, "05_tabela_master" b
WHERE b.sensor_id = s.id_sensor 
AND b.base_data = t."data"
AND b.base_placa = v.placa order by t.data;


SELECT *
FROM  "05_tabela_master" b order by b.base_data;

