import pytest
import pgdb
                     
@pytest.fixture
def pgdbConn(dbhost, db, frontenduser):
    return pgdb.connect(dbhost + ':' + db + ':' + frontenduser)

def test_insert_helper(pgdbConn):
    cursor=pgdbConn.cursor()

    args = {
        'name' : 'John Doe',
        'email' : 'john.doe@gmail.com',
        'capabilities' : '{"driving", "cooking"}'}
    
    cursor.execute("""
SELECT * from carpoolvote.submit_new_helper (
%(name)s,
%(email)s,
%(capabilities)s
)
""", args)
    results=cursor.fetchone()
    uuid=results[0]
    error_code=results[1]
    error_text=results[2]

    assert len(error_text)==0
    assert error_code==0
    assert len(uuid)>0
    
    pgdbConn.commit()