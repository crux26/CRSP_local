/*Nested queries example; see p.101, SQL User's Guide*/
libname sql 'D:\Dropbox\SAS_scripts\SQL Sample dataset';

proc sql;
    title 'Neighboring Cities';
    select a.City format=$10., a.State,
        a.Latitude 'Lat', a.Longitude 'Long',
        b.City format=$10., b.State,
        b.Latitude 'Lat', b.Longitude 'Long',
        sqrt(((b.latitude-a.latitude)**2) +
        ((b.longitude-a.longitude)**2)) as dist format=6.1
    from sql.uscitycoords a, sql.uscitycoords b
        where a.city ne b.city and
            calculated dist =
        (select min(sqrt(((d.latitude-c.latitude)**2) +
            ((d.longitude-c.longitude)**2)))
        from sql.uscitycoords c, sql.uscitycoords d
            where c.city = a.city and
                c.state = a.state and
                d.city ne c.city)
            order by a.city;
quit;

proc sql;
    title 'Neighboring Cities - 2';
    select a.City format=$10., a.State,
        a.Latitude 'Lat', a.Longitude 'Long',
        b.City format=$10., b.State,
        b.Latitude 'Lat', b.Longitude 'Long',
        sqrt(((b.latitude-a.latitude)**2) +
        ((b.longitude-a.longitude)**2)) as dist format=6.1
    from sql.uscitycoords a, sql.uscitycoords b
        where a.city ne b.city and
            calculated dist =
        (select min(sqrt(((d.latitude-c.latitude)**2) +
            ((d.longitude-c.longitude)**2)))
        from sql.uscitycoords c, sql.uscitycoords d
            where a.city = c.city and
                a.state = c.state and
                c.city ne d.city)
            order by a.city;
quit;
