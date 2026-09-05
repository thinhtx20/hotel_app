import 'package:equatable/equatable.dart';
import '../../../shared/models/invoice_model.dart';

abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();

  @override
  List<Object?> get props => [];
}

class InvoiceFetchRequested extends InvoiceEvent {
  final String? filterType;
  final int? year;
  final int? fromMonth;
  final int? toMonth;
  final int? month;
  final int? weekOffset;
  final String? timeFilterDisplayLabel;
  final bool isSilent;

  const InvoiceFetchRequested({
    this.filterType,
    this.year,
    this.fromMonth,
    this.toMonth,
    this.month,
    this.weekOffset,
    this.timeFilterDisplayLabel,
    this.isSilent = false,
  });

  @override
  List<Object?> get props => [
        filterType,
        year,
        fromMonth,
        toMonth,
        month,
        weekOffset,
        timeFilterDisplayLabel,
        isSilent,
      ];
}

class InvoiceRefreshRequested extends InvoiceEvent {
  const InvoiceRefreshRequested();
}

class InvoiceTabFilterChanged extends InvoiceEvent {
  final int tabIndex;

  const InvoiceTabFilterChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class InvoiceSearchChanged extends InvoiceEvent {
  final String searchQuery;

  const InvoiceSearchChanged(this.searchQuery);

  @override
  List<Object?> get props => [searchQuery];
}

class InvoiceLoadMoreRequested extends InvoiceEvent {
  const InvoiceLoadMoreRequested();
}

class InvoiceCreated extends InvoiceEvent {
  final InvoiceModel invoice;

  const InvoiceCreated(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class InvoicePaymentRecorded extends InvoiceEvent {
  final String invoiceId;
  final InvoiceModel updatedInvoice;
  final num amount;

  const InvoicePaymentRecorded({
    required this.invoiceId,
    required this.updatedInvoice,
    required this.amount,
  });

  @override
  List<Object?> get props => [invoiceId, updatedInvoice, amount];
}

class InvoiceRefundRecorded extends InvoiceEvent {
  final InvoiceModel updatedInvoice;

  const InvoiceRefundRecorded(this.updatedInvoice);

  @override
  List<Object?> get props => [updatedInvoice];
}
