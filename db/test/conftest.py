import pytest

def pytest_addoption(parser):
    parser.addoption("--db", action="store", default="carpool_unittest",
                     help=("Database Name, default=carpool"))
    parser.addoption("--admin", action="store", default="carpool_admin",
                     help=("Carpool Admin Username, default=carpool_admin"))
    parser.addoption("--frontend", action="store", default="carpool_web",
                     help=("Carpool Front End Username, default=carpool_web"))
    parser.addoption("--matchengine", action="store", default="carpool_match_engine",
                     help=("Carpool Front End Username, default=carpool_match_engine"))
    parser.addoption("--dbhost", action="store", default="/tmp",
                     help=("Database Host, default=/tmp"))
@pytest.fixture
def db(request):
    return request.config.getoption("--db")

@pytest.fixture
def adminuser(request):
    return request.config.getoption("--admin")

@pytest.fixture
def frontenduser(request):
    return request.config.getoption("--frontend")

@pytest.fixture
def matchengineuser(request):
    return request.config.getoption("--matchengine")

@pytest.fixture
def dbhost(request):
    return request.config.getoption("--dbhost")