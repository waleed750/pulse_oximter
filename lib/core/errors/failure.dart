import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable{

  @override
  List<Object> get props => [] ;
}

class ServerFailure implements Failure {
  String message;
  ServerFailure({
    required this.message,
  });
  @override  
  List<Object> get props => [];

  @override
  bool? get stringify => throw UnimplementedError();

}
class CacheFailure implements Failure{
  @override
  List<Object> get props => [];

  @override
  bool? get stringify => throw UnimplementedError();

}