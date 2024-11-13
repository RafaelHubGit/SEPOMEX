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


-- Tipo Asentamiento
CREATE TABLE CatTipoAsentamiento(
	IdTipoAsentamiento INT PRIMARY KEY IDENTITY(1,1),
	TipoAsentamiento VARCHAR(50) NOT NULL,
);

INSERT INTO CatTipoAsentamiento
SELECT d_tipo_asenta 
FROM CatSepomex cs
GROUP BY d_tipo_asenta 
ORDER BY d_tipo_asenta;


-- Zona (rural, urbana, semiurbano)
CREATE TABLE CatZonas (
    IdZona INT PRIMARY KEY IDENTITY(1,1),
    Zona VARCHAR(50) NOT NULL
);

INSERT INTO CatZonas (Zona)
SELECT DISTINCT d_zona
FROM CatSepomex
WHERE d_zona IS NOT NULL AND d_zona != ''
ORDER BY d_zona;

-- ESTADOS
CREATE TABLE CatEstados (
  IdEstado INT PRIMARY KEY IDENTITY(1,1),
  Estado VARCHAR(100) NOT NULL,
  ClaveInegi VARCHAR(2) NOT NULL
);

-- SET IDENTITY_INSERT CatEstados OFF;

INSERT INTO CatEstados (ClaveInegi, Estado)
SELECT DISTINCT c_estado, d_estado
FROM CatSepomex
ORDER BY c_estado;

-- SET IDENTITY_INSERT CatEstados ON;



-- CIUDADES 
CREATE TABLE CatCiudades (
    IdCiudad INT PRIMARY KEY IDENTITY(1,1),
    Ciudad VARCHAR(100) NOT NULL,
    IdEstado INT NOT NULL,
    CONSTRAINT UQ_CiudadEstado UNIQUE (Ciudad, IdEstado), -- Unicidad por ciudad y estado
    CONSTRAINT FK_CatCiudades_CatEstados FOREIGN KEY (IdEstado) REFERENCES CatEstados(IdEstado)
);

INSERT INTO CatCiudades (Ciudad, IdEstado)
SELECT DISTINCT 
    d_ciudad, 
    ce.IdEstado
FROM 
    CatSepomex cs
INNER JOIN 
    CatEstados ce ON cs.d_estado = ce.Estado 
WHERE 
    d_ciudad IS NOT NULL
AND d_ciudad != ' '
ORDER BY IdEstado, d_ciudad;



-- MUNICIPIOS
CREATE TABLE CatMunicipios (
  IdMunicipio INT PRIMARY KEY IDENTITY(1,1),
  Municipio VARCHAR(100) NOT NULL,
  ClaveInegi VARCHAR(3) NOT NULL,
  IdEstado INT NOT NULL,
  IdCiudad INT NULL,
  CONSTRAINT FK_CatMunicipios_CatEstados FOREIGN KEY (IdEstado) REFERENCES CatEstados(IdEstado),
  CONSTRAINT FK_CatMunicipios_CatCiudades FOREIGN KEY (IdCiudad) REFERENCES CatCiudades(IdCiudad)
);

-- SET IDENTITY_INSERT CatMunicipios OFF;

INSERT INTO CatMunicipios (Municipio, ClaveInegi, IdEstado, IdCiudad) -- Se insertan los municipios
SELECT DISTINCT
    cs.D_mnpio AS Municipio,
    cs.c_mnpio AS ClaveInegi,
    ce.IdEstado AS IdEstado,
    null
FROM
    CatSepomex cs
INNER JOIN
    CatEstados ce ON cs.d_estado = ce.Estado
WHERE
    cs.D_mnpio IS NOT NULL
ORDER BY IdEstado, Municipio, ClaveInegi;

UPDATE cm -- Se actualizan las ciudades en el municipio
SET cm.IdCiudad = cc.IdCiudad
FROM CatMunicipios cm
INNER JOIN CatSepomex cs ON cm.Municipio = cs.D_mnpio
INNER JOIN CatEstados ce ON cs.d_estado = ce.Estado
INNER JOIN CatCiudades cc ON cs.d_ciudad = cc.Ciudad AND ce.IdEstado = cc.IdEstado
WHERE cs.d_ciudad IS NOT NULL AND cs.d_ciudad != ' ';



-- COLONIAS
CREATE TABLE CatColonias (
  IdColonia INT PRIMARY KEY IDENTITY(1,1),
  Colonia VARCHAR(100) NOT NULL,
  IdMunicipio INT NOT NULL,
  IdTipoAsentamiento INT NULL,
  IdZona INT NOT NULL,
  CONSTRAINT FK_CatColonias_CatMunicipios FOREIGN KEY (IdMunicipio) REFERENCES CatMunicipios(IdMunicipio),
  CONSTRAINT FK_CatColonias_CatTipoAsentamiento FOREIGN KEY (IdTipoAsentamiento) REFERENCES CatTipoAsentamiento(IdTipoAsentamiento),
  CONSTRAINT FK_CatColonias_CatZonas FOREIGN KEY (IdZona) REFERENCES CatZonas(IdZona)
);

-- Insertar colonias en CatColonias con un JOIN adicional para el tipo de asentamiento
INSERT INTO CatColonias (Colonia, IdMunicipio, IdTipoAsentamiento, IdZona)
SELECT DISTINCT
    cs.d_asenta AS Colonia,
    cm.IdMunicipio AS IdMunicipio,
    null, -- Se agrega como null ya que al intentar agregarlo en la consulta duplicaba algunos registros
    cz.IdZona
FROM
    CatSepomex cs
INNER JOIN
    CatMunicipios cm ON cs.D_mnpio = cm.Municipio
INNER JOIN
    CatEstados ce ON cs.d_estado = ce.Estado AND cm.IdEstado = ce.IdEstado
-- INNER JOIN
--     CatTipoAsentamiento cta ON cs.d_tipo_asenta = cta.TipoAsentamiento
INNER JOIN
    CatZonas cz ON cs.d_zona = cz.Zona
WHERE
    cs.d_asenta IS NOT NULL
ORDER BY
    cm.IdMunicipio, cs.d_asenta;


UPDATE
	cc
SET
	cc.IdTipoAsentamiento = cta.IdTipoAsentamiento
FROM
	CatColonias cc
INNER JOIN CatSepomex cs ON
	cc.Colonia = cs.d_asenta
INNER JOIN CatTipoAsentamiento cta ON
	cta.TipoAsentamiento = cs.d_tipo_asenta
INNER JOIN CatMunicipios cm ON
	cc.IdMunicipio = cm.IdMunicipio
	AND cs.D_mnpio = cm.Municipio
INNER JOIN CatEstados ce ON
	cm.IdEstado = ce.IdEstado
	AND cs.d_estado = ce.Estado
WHERE cc.IdTipoAsentamiento IS NULL;




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
    cs.d_codigo IS NOT NULL
    AND cs.d_codigo != ''
ORDER BY IdColonia, CodigoPostal;
   
 

-- QUERY para hacer la busqueda por codigo postal
SELECT 
  ccp.CodigoPostal,
  cc.Colonia,
  cm.Municipio,
  ce.Estado,
  ccz.Zona,
  cta.TipoAsentamiento,
  ci.Ciudad
FROM 
  CatCodigosPostales ccp
INNER JOIN 
  CatColonias cc ON ccp.IdColonia = cc.IdColonia
INNER JOIN 
  CatMunicipios cm ON cc.IdMunicipio = cm.IdMunicipio
INNER JOIN 
  CatEstados ce ON cm.IdEstado = ce.IdEstado
INNER JOIN 
  CatZonas ccz ON cc.IdZona = ccz.IdZona
INNER JOIN 
  CatTipoAsentamiento cta ON cc.IdTipoAsentamiento = cta.IdTipoAsentamiento
INNER JOIN 
  CatCiudades ci ON cm.IdCiudad = ci.IdCiudad
WHERE 
  ccp.CodigoPostal = '57300';




