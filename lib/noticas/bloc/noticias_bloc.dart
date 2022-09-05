import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import '../../services/courierService.dart';
import '../../services/app_events.dart';
import '../../services/model/banner.dart';
import '../../services/model/noticia.dart';
import 'package:event/event.dart' as event;

part 'noticias_event.dart';
part 'noticias_state.dart';

class NoticiasBloc extends Bloc<NoticiasEvent, NoticiasState> {
  final CourierService _courierService;

  NoticiasBloc(this._courierService) : super(NoticiasLoadingState()) {

    GetIt.I<event.Event<LoginChanged>>().subscribe((args)  {
      add(LoadApiEvent());
    });

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
