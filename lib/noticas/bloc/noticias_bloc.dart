import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sampleapi/services/courierService.dart';
import '../../services/model/banner.dart';
import '../../services/model/noticia.dart';

part 'noticias_event.dart';
part 'noticias_state.dart';

class NoticiasBloc extends Bloc<NoticiasEvent, NoticiasState> {
  final CourierService _courierService;

  NoticiasBloc(this._courierService) : super(NoticiasLoadingState()) {

    on<LoadApiEvent>((event, emit) async {
      try {
        emit(NoticiasLoadingState());
        final noticias = await _courierService.getNoticias(event.ignoreCache);
        final banners = await _courierService.getBanners(hideIfLogged: true, ignoreCache: event.ignoreCache);
        emit(NoticiasLoadedState(noticias, banners));
      } on Exception catch (e) {
        emit(NoticiasErrorState());
      }
    });

  }
}
