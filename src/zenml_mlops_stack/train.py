import logging
from typing import Annotated, Tuple

import pandas as pd
from sklearn.base import ClassifierMixin
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.svm import SVC

import mlflow
from zenml import Model, pipeline, step
from zenml.config import DockerSettings

docker_settings = DockerSettings(python_package_installer="uv")


from zenml.integrations.mlflow.flavors.mlflow_experiment_tracker_flavor import (
    MLFlowExperimentTrackerSettings,
)

mlflow_settings = MLFlowExperimentTrackerSettings(
    experiment_name="Default_Project",
    nested=False,
    tags={},
)

from zenml.integrations.kubernetes.flavors import KubernetesOrchestratorSettings
from zenml.integrations.kubernetes.pod_settings import KubernetesPodSettings

k8s_settings = KubernetesOrchestratorSettings(
    orchestrator_pod_settings=KubernetesPodSettings(
        resources={
            "requests": {
                "cpu": "1",
                "memory": "2Gi"
            },
            "limits": {
                "cpu": "2",
                "memory": "4Gi"
            }
        }
    ),
    service_account_name="zenml-service-account"
)

@step(
    experiment_tracker="mlflow_tracker",
    settings={
        "experiment_tracker": mlflow_settings
    }
)
def training_data_loader() -> Tuple[
    # Notice we use a Tuple and Annotated to return 
    # multiple named outputs
    Annotated[pd.DataFrame, "X_train"],
    Annotated[pd.DataFrame, "X_test"],
    Annotated[pd.Series, "y_train"],
    Annotated[pd.Series, "y_test"],
]:
    """Load the iris dataset as a tuple of Pandas DataFrame / Series."""
    logging.info("Loading iris...")
    iris = load_iris(as_frame=True)
    logging.info("Splitting train and test...")
    X_train, X_test, y_train, y_test = train_test_split(
        iris.data, iris.target, test_size=0.2, shuffle=True, random_state=42
    )
    mlflow.log_param("dataset", "iris")
    return X_train, X_test, y_train, y_test


model = Model(
    # The name uniquely identifies this model
    # It usually represents the business use case
    name="iris_classifier",
    # The version specifies the version
    # If None or an unseen version is specified, it will be created
    # Otherwise, a version will be fetched.
    version=None, 
    # Some other properties may be specified
    license="Apache 2.0",
    description="A classification model for the iris dataset.",
)


@step(
    model=model,
    experiment_tracker="mlflow_tracker",
    settings={
        "experiment_tracker": mlflow_settings
    }
)
def svc_trainer(
    X_train: pd.DataFrame,
    y_train: pd.Series,
    gamma: float = 0.001,
) -> Tuple[
    Annotated[ClassifierMixin, "trained_model"],
    Annotated[float, "training_acc"],
]:
    """Train a sklearn SVC classifier."""

    model = SVC(gamma=gamma)
    model.fit(X_train.to_numpy(), y_train.to_numpy())

    train_acc = model.score(X_train.to_numpy(), y_train.to_numpy())
    print(f"Train accuracy: {train_acc}")
    
    mlflow.log_metric("Train Accuracy", train_acc)

    return model, train_acc


@pipeline(
    settings={
        "docker": docker_settings,
        "orchestrator": k8s_settings
    },
    model=model
)
def training_pipeline(gamma: float = 0.002):
    X_train, X_test, y_train, y_test = training_data_loader()
    svc_trainer(gamma=gamma, X_train=X_train, y_train=y_train)


if __name__ == "__main__":
    training_pipeline(gamma=0.0015)