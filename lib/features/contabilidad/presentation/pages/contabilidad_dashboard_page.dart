import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/asiento_model.dart';
import '../../data/models/cuenta_contable_model.dart';
import '../providers/contabilidad_provider.dart';

class ContabilidadDashboardPage extends StatefulWidget {
  const ContabilidadDashboardPage({super.key});

  @override
  State<ContabilidadDashboardPage> createState() => _ContabilidadDashboardPageState();
}

class _ContabilidadDashboardPageState extends State<ContabilidadDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContabilidadProvider>().cargarDatosIniciales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Contabilidad'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Asientos'),
              Tab(text: 'Plan de cuentas'),
            ],
          ),
        ),
        floatingActionButton: Consumer<ContabilidadProvider>(
          builder: (context, provider, child) {
            final hayCuentas = provider.cuentas.where((c) => c.esImputable).isNotEmpty;
            return FloatingActionButton.extended(
              onPressed: hayCuentas ? () => _mostrarNuevoAsientoSheet(context) : null,
              icon: const Icon(Icons.add_chart),
              label: const Text('Nuevo asiento'),
            );
          },
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: TabBarView(
            children: [
              _AsientosTab(onVerDetalle: _mostrarDetalleAsiento),
              _PlanCuentasTab(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDetalleAsiento(BuildContext context, AsientoResumen resumen) async {
    final provider = context.read<ContabilidadProvider>();
    final movimientos = await provider.obtenerMovimientos(resumen.asiento.id!);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Asiento ${resumen.asiento.numero}',
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 8),
              Text(resumen.asiento.descripcion ?? 'Sin descripción'),
              const Divider(height: 32),
              ...movimientos.map(
                (mov) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${mov.cuentaCodigo ?? ''} · ${mov.cuentaNombre ?? ''}'),
                  subtitle: mov.detalle != null && mov.detalle!.isNotEmpty
                      ? Text(mov.detalle!)
                      : null,
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Debe: ${mov.debe.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Haber: ${mov.haber.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _mostrarNuevoAsientoSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _NuevoAsientoSheet(),
    );
  }
}

class _AsientosTab extends StatelessWidget {
  final void Function(BuildContext context, AsientoResumen resumen) onVerDetalle;

  const _AsientosTab({
    required this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ContabilidadProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.asientos.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (provider.errorMessage != null && provider.asientos.isEmpty) {
          return _ErrorState(message: provider.errorMessage!);
        }

        if (provider.asientos.isEmpty) {
          return const _EmptyState();
        }

        return RefreshIndicator(
          onRefresh: provider.refrescar,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.asientos.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _ResumenTotales(provider: provider);
              }

              final resumen = provider.asientos[index - 1];
              return _AsientoCard(
                resumen: resumen,
                onTap: () => onVerDetalle(context, resumen),
              );
            },
          ),
        );
      },
    );
  }
}

class _PlanCuentasTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ContabilidadProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.cuentas.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (provider.cuentas.isEmpty) {
          return const _EmptyState(
            mensaje: 'Aún no se cargó el plan de cuentas.',
          );
        }

        return RefreshIndicator(
          onRefresh: provider.refrescar,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: provider.cuentas.length,
            itemBuilder: (context, index) {
              final cuenta = provider.cuentas[index];
              return _CuentaCard(cuenta: cuenta);
            },
          ),
        );
      },
    );
  }
}

class _ResumenTotales extends StatelessWidget {
  final ContabilidadProvider provider;

  const _ResumenTotales({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ResumenValor(
              etiqueta: 'Debe',
              valor: provider.totalDebe,
              color: AppColors.primary,
            ),
            _ResumenValor(
              etiqueta: 'Haber',
              valor: provider.totalHaber,
              color: AppColors.secondary,
            ),
            _ResumenValor(
              etiqueta: 'Diferencia',
              valor: provider.diferencia,
              color: provider.diferencia.abs() < 0.01
                  ? AppColors.success
                  : AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenValor extends StatelessWidget {
  final String etiqueta;
  final double valor;
  final Color color;

  const _ResumenValor({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: AppTextStyles.caption.copyWith(color: AppColors.textMedium),
        ),
        const SizedBox(height: 4),
        Text(
          valor.toStringAsFixed(2),
          style: AppTextStyles.h4.copyWith(color: color),
        ),
      ],
    );
  }
}

class _AsientoCard extends StatelessWidget {
  final AsientoResumen resumen;
  final VoidCallback onTap;

  const _AsientoCard({
    required this.resumen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = resumen.asiento.fecha;
    final fechaTexto = '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        onTap: onTap,
        title: Text(resumen.asiento.numero),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(resumen.asiento.descripcion ?? 'Sin descripción'),
            const SizedBox(height: 4),
            Text(
              'Fecha: $fechaTexto',
              style: const TextStyle(color: AppColors.textMedium),
            ),
            Text(
              'Movimientos: ${resumen.movimientos}',
              style: const TextStyle(color: AppColors.textMedium),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Debe: ${resumen.totalDebe.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'Haber: ${resumen.totalHaber.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _CuentaCard extends StatelessWidget {
  final CuentaContableModel cuenta;

  const _CuentaCard({required this.cuenta});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${cuenta.codigo} · ${cuenta.nombre}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${cuenta.tipo}'),
            if (cuenta.descripcion != null && cuenta.descripcion!.isNotEmpty)
              Text(cuenta.descripcion!),
          ],
        ),
        trailing: Icon(
          cuenta.esImputable ? Icons.check_circle : Icons.account_tree,
          color: cuenta.esImputable ? AppColors.success : AppColors.textMedium,
        ),
      ),
    );
  }
}

class _NuevoAsientoSheet extends StatefulWidget {
  const _NuevoAsientoSheet();

  @override
  State<_NuevoAsientoSheet> createState() => _NuevoAsientoSheetState();
}

class _NuevoAsientoSheetState extends State<_NuevoAsientoSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _fecha;
  late TextEditingController _descripcionController;
  late TextEditingController _montoController;
  late TextEditingController _detalleDebeController;
  late TextEditingController _detalleHaberController;
  int? _cuentaDebeId;
  int? _cuentaHaberId;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ContabilidadProvider>();
    final cuentasImputables = provider.cuentas.where((c) => c.esImputable).toList();
    _fecha = DateTime.now();
    _descripcionController = TextEditingController();
    _montoController = TextEditingController();
    _detalleDebeController = TextEditingController();
    _detalleHaberController = TextEditingController();
    if (cuentasImputables.isNotEmpty) {
      _cuentaDebeId = cuentasImputables.first.id;
      _cuentaHaberId = cuentasImputables.length > 1
          ? cuentasImputables[1].id
          : cuentasImputables.first.id;
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    _detalleDebeController.dispose();
    _detalleHaberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContabilidadProvider>();
    final cuentas = provider.cuentas.where((c) => c.esImputable).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Registrar asiento manual',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final seleccion = await showDatePicker(
                    context: context,
                    initialDate: _fecha,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (seleccion != null) {
                    setState(() {
                      _fecha = seleccion;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  'Fecha: ${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}',
                ),
              ),
            ),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
              ),
              validator: (value) {
                final texto = value?.trim();
                if (texto == null || texto.isEmpty) {
                  return 'Ingrese un monto';
                }
                final monto = double.tryParse(texto.replaceAll(',', '.'));
                if (monto == null || monto <= 0) {
                  return 'Monto inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _cuentaDebeId,
              decoration: const InputDecoration(labelText: 'Cuenta (Debe)'),
              items: cuentas
                  .map(
                    (cuenta) => DropdownMenuItem<int>(
                      value: cuenta.id,
                      child: Text('${cuenta.codigo} · ${cuenta.nombre}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _cuentaDebeId = value),
              validator: (value) => value == null ? 'Seleccione cuenta debe' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detalleDebeController,
              decoration: const InputDecoration(
                labelText: 'Detalle debe (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _cuentaHaberId,
              decoration: const InputDecoration(labelText: 'Cuenta (Haber)'),
              items: cuentas
                  .map(
                    (cuenta) => DropdownMenuItem<int>(
                      value: cuenta.id,
                      child: Text('${cuenta.codigo} · ${cuenta.nombre}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _cuentaHaberId = value),
              validator: (value) => value == null ? 'Seleccione cuenta haber' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detalleHaberController,
              decoration: const InputDecoration(
                labelText: 'Detalle haber (opcional)',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: provider.isSaving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            final monto = double.parse(
                              _montoController.text.trim().replaceAll(',', '.'),
                            );

                            final exito = await provider.crearAsientoManual(
                              fecha: _fecha,
                              descripcion: _descripcionController.text.trim().isEmpty
                                  ? null
                                  : _descripcionController.text.trim(),
                              cuentaDebeId: _cuentaDebeId!,
                              cuentaHaberId: _cuentaHaberId!,
                              monto: monto,
                              detalleDebe: _detalleDebeController.text.trim().isEmpty
                                  ? null
                                  : _detalleDebeController.text.trim(),
                              detalleHaber: _detalleHaberController.text.trim().isEmpty
                                  ? null
                                  : _detalleHaberController.text.trim(),
                            );

                            if (exito && context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                    child: provider.isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar asiento'),
                  ),
                ),
              ],
            ),
            if (provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String mensaje;

  const _EmptyState({
    this.mensaje = 'No hay información disponible aún.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: AppTextStyles.body2.copyWith(color: AppColors.textMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body2.copyWith(color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}
