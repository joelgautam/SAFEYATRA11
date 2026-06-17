from django.conf import settings


class PredefinedRouteRouter:
    """
    A router to control all database operations on models in the
    core application that should go to the routes_db.
    """

    route_app_labels = {"core"}
    route_models = {"predefinedroute"}

    def _routes_db(self):
        return "routes_db" if "routes_db" in settings.DATABASES else "default"

    def db_for_read(self, model, **hints):
        if model._meta.model_name in self.route_models:
            return self._routes_db()
        return "default"

    def db_for_write(self, model, **hints):
        if model._meta.model_name in self.route_models:
            return self._routes_db()
        return "default"

    def allow_relation(self, obj1, obj2, **hints):
        """
        Allow relations if a model in the core app is involved.
        """
        if (
            obj1._meta.model_name in self.route_models or
            obj2._meta.model_name in self.route_models
        ):
            return True
        return None

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        """
        Make sure the predefinedroute model only appears in the 'routes_db'
        database.
        """
        if model_name in self.route_models:
            return db == self._routes_db()
        return db == "default"
