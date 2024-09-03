CREATE TABLE CatSepomex (
  d_codigo VARCHAR(15),
  d_asenta VARCHAR(100),
  d_tipo_asenta VARCHAR(50),
  D_mnpio VARCHAR(100),
  d_estado VARCHAR(100),
  d_ciudad VARCHAR(100),
  d_CP VARCHAR(10),
  c_estado VARCHAR(10),
  c_oficina VARCHAR(10),
  c_CP VARCHAR(10),
  c_tipo_asenta VARCHAR(50),
  c_mnpio VARCHAR(100),
  id_asenta_cpcons INT,
  d_zona VARCHAR(50),
  c_cve_ciudad VARCHAR(10)
);


SELECT *
FROM CatSepomex cs
WHERE d_codigo = 06030;

SELECT COUNT(*)
FROM (
SELECT DISTINCT d_asenta, c_estado, D_mnpio
FROM CatSepomex cs
) AS abcd;


-- ESTADOS
CREATE TABLE CatEstados (
  IdEstado INT PRIMARY KEY IDENTITY(1,1),
  Estado VARCHAR(100) NOT NULL
);

SET IDENTITY_INSERT CatEstados OFF;

INSERT INTO CatEstados (IdEstado, Estado)
SELECT DISTINCT c_estado, d_estado
FROM CatSepomex
ORDER BY c_estado;

SET IDENTITY_INSERT CatEstados ON;







-- MUNICIPIOS
CREATE TABLE CatMunicipios (
  IdMunicipio INT PRIMARY KEY IDENTITY(1,1),
  Municipio VARCHAR(100) NOT NULL,
  IdEstado INT NOT NULL,
  CONSTRAINT FK_CatMunicipios_CatEstados FOREIGN KEY (IdEstado) REFERENCES CatEstados(IdEstado)
);

SET IDENTITY_INSERT CatMunicipios OFF;

INSERT INTO CatMunicipios (Municipio, IdEstado)
SELECT DISTINCT
    cs.D_mnpio AS Municipio,
    ce.IdEstado AS IdEstado
FROM
    CatSepomex cs
INNER JOIN
    CatEstados ce ON cs.d_estado = ce.Estado
WHERE
    cs.D_mnpio IS NOT NULL;



-- COLONIAS
CREATE TABLE CatColonias (
  IdColonia INT PRIMARY KEY IDENTITY(1,1),
  Colonia VARCHAR(100) NOT NULL,
  IdMunicipio INT NOT NULL,
  CONSTRAINT FK_CatColonias_CatMunicipios FOREIGN KEY (IdMunicipio) REFERENCES CatMunicipios(IdMunicipio)
);

INSERT INTO CatColonias (Colonia, IdMunicipio)
SELECT DISTINCT
    cs.d_asenta AS Colonia,
    cm.IdMunicipio AS IdMunicipio
FROM
    CatSepomex cs
INNER JOIN
    CatMunicipios cm ON cs.D_mnpio = cm.Municipio
INNER JOIN
    CatEstados ce ON cs.d_estado = ce.Estado AND cm.IdEstado = ce.IdEstado
WHERE
    cs.d_asenta IS NOT NULL;


--CODIGOS POSTALES
CREATE TABLE CatCodigosPostales (
  IdCodigoPostal INT PRIMARY KEY IDENTITY(1,1),
  CodigoPostal VARCHAR(10) NOT NULL,
  IdColonia INT NOT NULL,
  CONSTRAINT FK_CatCodigosPostales_CatColonias FOREIGN KEY (IdColonia) REFERENCES CatColonias(IdColonia)
);

INSERT INTO CatCodigosPostales (CodigoPostal, IdColonia)
SELECT DISTINCT
    cs.d_codigo AS CodigoPostal,
    cc.IdColonia AS IdColonia
FROM
    CatSepomex cs
INNER JOIN
    CatColonias cc ON cs.d_asenta = cc.Colonia
INNER JOIN
    CatMunicipios cm ON cs.D_mnpio = cm.Municipio AND cc.IdMunicipio = cm.IdMunicipio
INNER JOIN
    CatEstados ce ON cs.d_estado = ce.Estado AND cm.IdEstado = ce.IdEstado
WHERE
    cs.d_codigo IS NOT NULL;
   
 

   
SELECT 
    cp.CodigoPostal,
    col.Colonia,
    mun.Municipio,
    est.Estado
FROM 
    CatCodigosPostales cp
INNER JOIN 
    CatColonias col ON cp.IdColonia = col.IdColonia
INNER JOIN 
    CatMunicipios mun ON col.IdMunicipio = mun.IdMunicipio
INNER JOIN 
    CatEstados est ON mun.IdEstado = est.IdEstado
WHERE 
    cp.CodigoPostal = '55712'; -- 55712
   
   
SELECT *
FROM CatSepomex cs
WHERE cs.d_asenta LIKE '%Tabac%';




