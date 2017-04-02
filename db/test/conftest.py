import pytest

def pytest_addoption(parser):
    parser.addoption("--dbname", action="store", default="carpool",
                     help=("Database Name, default=carpool"))
    parser.addoption("--username", action="store", default="carpool_web",
                     help=("Database Username, default=carpool_web"))
@pytest.fixture
def dbname(request):
    return request.config.getoption("--dbname")

@pytest.fixture
def username(request):
    return request.config.getoption("--username")
