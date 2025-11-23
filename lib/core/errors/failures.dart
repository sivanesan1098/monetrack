abstract class Failure {
  final String message;
  const Failure(this.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
