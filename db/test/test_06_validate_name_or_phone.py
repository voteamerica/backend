import pytest
import pgdb
                     
@pytest.fixture
def pgdbConn(dbhost, db, frontenduser):
    return pgdb.connect(dbhost + ':' + db + ':' + frontenduser)

    
def test_validate_name_or_phone(pgdbConn):
    
    cursor = pgdbConn.cursor()
    cursor.execute("""SELECT * FROM carpoolvote.validate_name_or_phone(%(parameter)s, %(name)s, %(number)s) """, 
    {'parameter' : 'David', 'name' : 'DAVID', 'number' : '702664656'}
    )
    results = cursor.fetchone()
    assert results[0] == True

    cursor.execute("""SELECT * FROM carpoolvote.validate_name_or_phone(%(parameter)s, %(name)s, %(number)s) """, 
    {'parameter' : 'Dasvid', 'name' : 'DAVID', 'number' : '702664656'}
    )
    results = cursor.fetchone()
    assert results[0] == False
 
    cursor.execute("""SELECT * FROM carpoolvote.validate_name_or_phone(%(parameter)s, %(name)s, %(number)s) """, 
    {'parameter' : '+16577656534', 'name' : 'DAVID', 'number' : '165-7765-6534'}
    )
    results = cursor.fetchone()
    assert results[0] == True
    
    cursor.execute("""SELECT * FROM carpoolvote.validate_name_or_phone(%(parameter)s, %(name)s, %(number)s) """, 
    {'parameter' : '+16577656534', 'name' : 'DAVID', 'number' : '657-765-6534'}
    )
    results = cursor.fetchone()
    assert results[0] == True
        
    cursor.execute("""SELECT * FROM carpoolvote.validate_name_or_phone(%(parameter)s, %(name)s, %(number)s) """, 
    {'parameter' : '+16577656534', 'name' : 'DAVID', 'number' : '+16577656534'}
    )
    results = cursor.fetchone()
    assert results[0] == True
    
    cursor.execute("""SELECT * FROM carpoolvote.validate_name_or_phone(%(parameter)s, %(name)s, %(number)s) """, 
    {'parameter' : '', 'name' : '', 'number' : '+16577656534'}
    )
    results = cursor.fetchone()
    assert results[0] == True