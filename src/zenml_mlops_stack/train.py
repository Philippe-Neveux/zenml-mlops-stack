import logging
from math import gamma
from typing import Annotated, Tuple, Literal

import pandas as pd
from loguru import logger
from sklearn.base import ClassifierMixin
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression

import mlflow
from zenml import Model, pipeline, step
from zenml.config import DockerSettings
from zenml.config.docker_settings import PythonPackageInstaller

docker_settings = DockerSettings(
    python_package_installer=PythonPackageInstaller.UV
    build_config={"build_options": {"platform": "linux/amd64"}}
)


from zenml.integrations.mlflow.flavors.mlflow_experiment_tracker_flavor import (
    MLFlowExperimentTrackerSettings,
)

mlflow_settings = MLFlowExperimentTrackerSettings(
    experiment_name="Default_Project",
    nested=True,
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
    logger.info(f"Train shape: {X_train.shape}, Test shape: {X_test.shape}")
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
def logistic_regression_trainer(
    X_train: pd.DataFrame,
    y_train: pd.Series,
    penalty: Literal["l1", "l2"] = "l2",
) -> Tuple[
    Annotated[ClassifierMixin, "trained_model"],
    Annotated[float, "training_acc"],
]:
    """Train a sklearn Logistic Regression classifier."""

    model = LogisticRegression(penalty=penalty, random_state=42)
    model.fit(X_train.to_numpy(), y_train.to_numpy())

    train_acc = model.score(X_train.to_numpy(), y_train.to_numpy())
    print(f"Train accuracy: {train_acc}")
    
    mlflow.log_metric("Train Accuracy", train_acc)
    mlflow.log_param("penalty", penalty)

    mlflow.sklearn.log_model(
        sk_model=model,
        artifact_path="iris_logistic_model",
        registered_model_name="iris_classifier_lr"
    )
    
    logger.info("Model training completed and logged to MLflow.")

    return model, train_acc


@pipeline(
    enable_cache=False,
    settings={
        "docker": docker_settings,
        "orchestrator": k8s_settings
    },
    model=model
)
def training_pipeline(
    penalty: Literal["l1", "l2"] = "l2"
):
    X_train, X_test, y_train, y_test = training_data_loader()
    logistic_regression_trainer(penalty=penalty, X_train=X_train, y_train=y_train)


if __name__ == "__main__":
    training_pipeline(penalty="l2")