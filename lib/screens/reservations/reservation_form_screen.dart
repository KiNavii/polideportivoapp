import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/models/installation_model.dart';
import 'package:deportivov1/screens/reservations/court_selection_screen.dart';
import 'package:deportivov1/services/auth_provider.dart';
import 'package:deportivov1/services/reservation_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ReservationFormScreen extends StatefulWidget {
  final Installation installation;

  const ReservationFormScreen({Key? key, required this.installation})
    : super(key: key);

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  DateTime _selectedDate = DateTime.now();
  String _startTime = '09:00';
  String _endTime = '10:00';
  bool _isLoading = false;
  String? _errorMessage;
  final List<String> _availableHours = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
  ];

  // Verificar si la instalación tiene pistas
  bool get _installationHasCourts =>
      widget.installation.caracteristicasJson?['tiene_pistas'] == true;

  @override
  void initState() {
    super.initState();

    // Establecer horarios predeterminados según las características de la instalación
    if (widget.installation.horaApertura != null) {
      _startTime = widget.installation.horaApertura!;

      // Calcular hora fin por defecto (1 hora después del inicio)
      final parts = _startTime.split(':');
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);

      final DateTime startDateTime = DateTime(2022, 1, 1, hours, minutes);
      final DateTime endDateTime = startDateTime.add(const Duration(hours: 1));

      _endTime =
          '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.darkColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _checkAvailabilityAndReserve() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Si la instalación tiene pistas, redirigir a la pantalla de selección
      if (_installationHasCourts) {
        setState(() {
          _isLoading = false;
        });

        // Navegar a la pantalla de selección de pistas
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CourtSelectionScreen(
                  installation: widget.installation,
                  selectedDate: _selectedDate,
                  startTime: _startTime,
                  endTime: _endTime,
                ),
          ),
        );

        // Si se realizó la reserva con éxito, volver a la pantalla principal
        if (result == true) {
          Navigator.of(context).pop(true);
        }
        return;
      }

      // Verificar disponibilidad si no tiene pistas
      final isAvailable = await ReservationService.checkAvailability(
        installationId: widget.installation.id,
        date: _selectedDate,
        startTime: _startTime,
        endTime: _endTime,
      );

      if (!isAvailable) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'La instalación no está disponible en el horario seleccionado';
        });
        return;
      }

      // Crear reserva
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user!.id;

      final success = await ReservationService.createReservation(
        userId: userId,
        installationId: widget.installation.id,
        date: _selectedDate,
        startTime: _startTime,
        endTime: _endTime,
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva realizada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        // Volver a la pantalla anterior después de una breve pausa
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pop(true); // Devolver true para indicar éxito
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo realizar la reserva'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al verificar disponibilidad: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Reserva')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la instalación
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.installation.nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.installation.descripcion != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          widget.installation.descripcion!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    if (widget.installation.ubicacion != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.installation.ubicacion!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Mostrar si tiene pistas
                    if (_installationHasCourts)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sports_tennis,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Esta instalación tiene pistas',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Selección de fecha
            const Text(
              'Fecha de reserva',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Selección de hora
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hora inicio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _startTime,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items:
                            _availableHours
                                .map(
                                  (hour) => DropdownMenuItem<String>(
                                    value: hour,
                                    child: Text(hour),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _startTime = value;
                              // Actualizar hora fin si necesario
                              if (_compareTimeStrings(_startTime, _endTime) >=
                                  0) {
                                // Si la hora inicio es mayor o igual a la fin, actualizar fin
                                final parts = _startTime.split(':');
                                int hours = int.parse(parts[0]);
                                int minutes = int.parse(parts[1]);

                                final DateTime startDateTime = DateTime(
                                  2022,
                                  1,
                                  1,
                                  hours,
                                  minutes,
                                );
                                final DateTime endDateTime = startDateTime.add(
                                  const Duration(hours: 1),
                                );

                                _endTime =
                                    '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hora fin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _endTime,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items:
                            _availableHours
                                .map(
                                  (hour) => DropdownMenuItem<String>(
                                    value: hour,
                                    child: Text(hour),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null &&
                              _compareTimeStrings(_startTime, value) < 0) {
                            setState(() {
                              _endTime = value;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'La hora de fin debe ser posterior a la hora de inicio',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Mensaje de error
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const Spacer(),

            // Botón para reservar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkAvailabilityAndReserve,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          _installationHasCourts
                              ? 'CONTINUAR'
                              : 'RESERVAR AHORA',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Función auxiliar para comparar strings de hora (HH:MM)
  int _compareTimeStrings(String time1, String time2) {
    // Convertir a horas y minutos
    List<int> parts1 = time1.split(':').map((e) => int.parse(e)).toList();
    List<int> parts2 = time2.split(':').map((e) => int.parse(e)).toList();

    // Comparar horas
    if (parts1[0] != parts2[0]) {
      return parts1[0].compareTo(parts2[0]);
    }

    // Si las horas son iguales, comparar minutos
    return parts1[1].compareTo(parts2[1]);
  }
}
