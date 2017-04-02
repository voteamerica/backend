import pytest

def pytest_addoption(parser):
    parser.addoption("--dbname", action="store", default="carpool",
                     help=("Database Name, default=carpool"))

@pytest.fixture
def dbname(request):
    return request.config.getoption("--dbname")


