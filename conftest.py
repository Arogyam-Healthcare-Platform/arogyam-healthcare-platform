import sys
from pathlib import Path

# Root Pytest conftest: Add all microservices to sys.path so VS Code Test Explorer can discover tests cleanly
root_dir = Path(__file__).parent.resolve()

auth_service = root_dir / "arogyam-auth-service"
if auth_service.exists() and str(auth_service) not in sys.path:
    sys.path.insert(0, str(auth_service))

patient_service = root_dir / "arogyam-patient-service"
if patient_service.exists() and str(patient_service) not in sys.path:
    sys.path.insert(0, str(patient_service))
