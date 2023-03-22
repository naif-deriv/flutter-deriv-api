import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_deriv_api/api/exceptions/exceptions.dart';
import 'package:flutter_deriv_api/api/response/active_symbols_response_result.dart';
import 'package:flutter_deriv_api/api/response/contracts_for_response_result.dart';
import 'package:flutter_deriv_api/basic_api/generated/api.dart';

import '../active_symbols/active_symbols_bloc.dart';

part 'available_contracts_event.dart';
part 'available_contracts_state.dart';

/// AvailableContractsBloc
class AvailableContractsBloc
    extends Bloc<AvailableContractsEvent, AvailableContractsState> {
  /// Initializes
  AvailableContractsBloc(ActiveSymbolsBloc activeSymbolsBloc)
      : super(AvailableContractsLoading()) {
    activeSymbolsBloc.stream.listen((ActiveSymbolsState activeSymbolsState) {
      if (activeSymbolsState is ActiveSymbolsLoaded) {
        add(
          FetchAvailableContracts(
            activeSymbol: activeSymbolsState.selectedSymbol,
          ),
        );
      }
    });
    on<AvailableContractsEvent>(
      (AvailableContractsEvent event,
          Emitter<AvailableContractsState> emit) async {
        if (event is FetchAvailableContracts) {
          emit(AvailableContractsLoading());

          try {
            final ContractsForResponse contracts =
                await _fetchAvailableContracts(event.activeSymbol);

            emit(AvailableContractsLoaded(contracts: contracts.contractsFor!));
          } on ContractsForSymbolException catch (error) {
            emit(AvailableContractsError(error.message));
          }
        } else if (event is SelectContract) {
          if (state is AvailableContractsLoaded) {
            final AvailableContractsLoaded loadedState =
                state as AvailableContractsLoaded;

            emit(AvailableContractsLoaded(
              contracts: loadedState.contracts,
              selectedContract: loadedState.contracts.available[event.index],
            ));
          } else {
            emit(AvailableContractsLoading());
            add(FetchAvailableContracts());
          }
        }
      },
    );
  }

  Future<ContractsForResponse> _fetchAvailableContracts(
    ActiveSymbolsItem? selectedSymbol,
  ) async =>
      ContractsForResponse.fetchContractsForSymbol(ContractsForRequest(
        contractsFor: selectedSymbol?.symbol,
      ));
}
