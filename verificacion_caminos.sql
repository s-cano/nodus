SET search_path = nodus, public;

SELECT c.codigo, c.descripcion, c.estado,
       ro.codigo AS rep_origen, po.identificador AS pto_origen,
       rd.codigo AS rep_destino, pd.identificador AS pto_destino,
       COUNT(r.orden) AS saltos
FROM camino c
JOIN puerto po ON po.id = c.puerto_origen_id
JOIN repartidor ro ON ro.id = po.repartidor_id
JOIN puerto pd ON pd.id = c.puerto_destino_id
JOIN repartidor rd ON rd.id = pd.repartidor_id
JOIN recorrido r ON r.camino_id = c.id
WHERE c.descripcion LIKE 'MPLS%'
GROUP BY c.codigo, c.descripcion, c.estado,
         ro.codigo, po.identificador, rd.codigo, pd.identificador
ORDER BY c.codigo;
