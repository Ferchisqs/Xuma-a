import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/companion_entity.dart';

class CompanionInfoDialog extends StatelessWidget {
  final CompanionEntity? companion;
  final CompanionType? animalType;
  
  const CompanionInfoDialog({
    Key? key,
    this.companion,
    this.animalType,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final type = companion?.type ?? animalType ?? CompanionType.dexter;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        // 🔧 LIMITAR ALTURA MÁXIMA PARA EVITAR DESBORDAMIENTO
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85, // 85% de la pantalla
          maxWidth: MediaQuery.of(context).size.width * 0.9,   // 90% del ancho
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20), // 🔧 REDUCIR PADDING
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView( // 🔧 HACER SCROLLABLE
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con ícono
              _buildHeader(type),
              
              const SizedBox(height: 16), // 🔧 REDUCIR ESPACIO
              
              // Datos curiosos del animal
              _buildCuriousFacts(type),
              
              const SizedBox(height: 16), // 🔧 REDUCIR ESPACIO
              
              // Dedicatoria (solo si hay compañero específico)
              if (companion != null) ...[
                _buildDedication(companion!),
                const SizedBox(height: 16), // 🔧 REDUCIR ESPACIO
              ],
              
              // Botón cerrar
              _buildCloseButton(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(CompanionType type) {
    return Column(
      children: [
        Container(
          width: 60, // 🔧 REDUCIR TAMAÑO
          height: 60, // 🔧 REDUCIR TAMAÑO
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getAnimalColor(type),
                _getAnimalColor(type).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(30), // 🔧 AJUSTAR RADIO
            boxShadow: [
              BoxShadow(
                color: _getAnimalColor(type).withOpacity(0.3),
                blurRadius: 10, // 🔧 REDUCIR BLUR
                offset: const Offset(0, 4), // 🔧 REDUCIR OFFSET
              ),
            ],
          ),
          child: Icon(
            _getAnimalIcon(type),
            color: Colors.white,
            size: 30, // 🔧 REDUCIR TAMAÑO ÍCONO
          ),
        ),
        
        const SizedBox(height: 12), // 🔧 REDUCIR ESPACIO
        
        Text(
          _getAnimalTitle(type),
          style: AppTextStyles.h4.copyWith( // 🔧 USAR H4 EN LUGAR DE H3
            color: _getAnimalColor(type),
            fontWeight: FontWeight.bold,
          ),
        ),
        
        Text(
          _getAnimalSubtitle(type),
          style: AppTextStyles.bodySmall.copyWith( // 🔧 USAR BODYSMALL
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildCuriousFacts(CompanionType type) {
    final facts = _getCuriousFacts(type);
    
    return Container(
      padding: const EdgeInsets.all(16), // 🔧 REDUCIR PADDING
      decoration: BoxDecoration(
        color: _getAnimalColor(type).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12), // 🔧 REDUCIR RADIO
        border: Border.all(
          color: _getAnimalColor(type).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: _getAnimalColor(type),
                size: 18, // 🔧 REDUCIR TAMAÑO ÍCONO
              ),
              const SizedBox(width: 6), // 🔧 REDUCIR ESPACIO
              Text(
                'Datos Curiosos',
                style: AppTextStyles.bodyLarge.copyWith( // 🔧 USAR BODYLARGE
                  color: _getAnimalColor(type),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12), // 🔧 REDUCIR ESPACIO
          
          ...facts.asMap().entries.map((entry) {
            final index = entry.key;
            final fact = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8), // 🔧 REDUCIR ESPACIO
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20, // 🔧 REDUCIR TAMAÑO
                    height: 20, // 🔧 REDUCIR TAMAÑO
                    decoration: BoxDecoration(
                      color: _getAnimalColor(type),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10, // 🔧 REDUCIR FUENTE
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // 🔧 REDUCIR ESPACIO
                  Expanded(
                    child: Text(
                      fact,
                      style: AppTextStyles.bodySmall.copyWith( // 🔧 USAR BODYSMALL
                        color: AppColors.textPrimary,
                        height: 1.3, // 🔧 REDUCIR ALTURA DE LÍNEA
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildDedication(CompanionEntity companion) {
    final dedication = _getDedication(companion);
    
    return Container(
      padding: const EdgeInsets.all(16), // 🔧 REDUCIR PADDING
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.pink[50]!,
            Colors.purple[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12), // 🔧 REDUCIR RADIO
        border: Border.all(
          color: Colors.pink.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: Colors.pink[600],
                size: 18, // 🔧 REDUCIR TAMAÑO ÍCONO
              ),
              const SizedBox(width: 6), // 🔧 REDUCIR ESPACIO
              Expanded( // 🔧 HACER EXPANDIBLE PARA EVITAR OVERFLOW
                child: Text(
                  'Dedicatoria Especial',
                  style: AppTextStyles.bodyLarge.copyWith( // 🔧 USAR BODYLARGE
                    color: Colors.pink[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10), // 🔧 REDUCIR ESPACIO
          
          // 🔧 CONTENEDOR CON ALTURA MÁXIMA PARA EL MENSAJE
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 100, // 🔧 ALTURA MÁXIMA PARA EL MENSAJE
            ),
            child: SingleChildScrollView(
              child: Text(
                '"${dedication['message']}"',
                style: AppTextStyles.bodySmall.copyWith( // 🔧 USAR BODYSMALL
                  color: AppColors.textPrimary,
                  fontStyle: FontStyle.italic,
                  height: 1.3, // 🔧 REDUCIR ALTURA DE LÍNEA
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8), // 🔧 REDUCIR ESPACIO
          
          Row(
            children: [
              const Spacer(),
              Text(
                '- ${dedication['author']}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.pink[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12), // 🔧 REDUCIR PADDING
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.close, color: Colors.white, size: 18), // 🔧 REDUCIR ÍCONO
            const SizedBox(width: 6), // 🔧 REDUCIR ESPACIO
            Text(
              'Cerrar',
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 🔧 DATOS CURIOSOS MÁS CORTOS PARA EVITAR DESBORDAMIENTO
  List<String> _getCuriousFacts(CompanionType type) {
    switch (type) {
      case CompanionType.dexter: // Chihuahua
        return [
          'Son la raza más pequeña del mundo, pero tienen cerebros grandes en proporción.',
          'Pueden vivir hasta 18 años, siendo muy longevos.',
          'Su nombre viene del estado mexicano de Chihuahua.',
          'Son excelentes guardianes a pesar de su tamaño.',
          'Buscan calor constantemente por su alta temperatura corporal.',
        ];
        
      case CompanionType.elly: // Panda
        return [
          'Comen bambú 12-16 horas al día, hasta 26 kg diarios.',
          'Nacen del tamaño de un ratón pero llegan a pesar 120 kg.',
          'Tienen un "falso pulgar" para agarrar bambú mejor.',
          'Solo quedan 1,864 pandas en estado salvaje.',
          'Son excelentes nadadores y trepadores.',
        ];
        
      case CompanionType.paxolotl: // Ajolote
        return [
          'Regeneran extremidades, órganos e incluso partes del cerebro.',
          'Son exclusivos de los lagos de Xochimilco en México.',
          'Mantienen características juveniles toda su vida.',
          'Están en peligro crítico, menos de 1,000 en libertad.',
          'Los aztecas los consideraban dioses terrestres.',
        ];
        
      case CompanionType.yami: // Jaguar
        return [
          'Tienen la mordida más fuerte de los felinos americanos.',
          'Son excelentes nadadores, únicos entre felinos grandes.',
          'Cada jaguar tiene rosetas únicas como huellas dactilares.',
          'Saltan hasta 6m horizontal y 3m vertical.',
          'Eran dioses en culturas prehispánicas.',
        ];
    }
  }
  

  Map<String, String> _getDedication(CompanionEntity companion) {
    switch (companion.id) {
      case 'dexter_baby':
        return {
          'message': 'Para mi perrito dexter , gracias por los 16 años a mi lado , mamá y yo te extrañamos',
          'author': 'Con amor, tu familia'
        };
      case 'dexter_young':
        return {
          'message': 'A Dexter , gracias por las noches de desvelo a mi lado pequeñin',
          'author': 'Con cariño'
        };
      case 'dexter_adult':
        return {
          'message': 'Para Dexter adulto, te extraño todos los días',
          'author': 'Siempre en mi corazón'
        };
        
      case 'elly_baby':
        return {
          'message': 'Para Dianelly, gracias por encontrarme y contarme chistes ',
          'author': 'Con ternura'
        };
      case 'elly_young':
        return {
          'message': 'A Elly, quien me enseñó que la paciencia y dulzura superan cualquier obstáculo.',
          'author': 'Tu admirador'
        };
      case 'elly_adult':
        return {
          'message': 'Para Elly madura, símbolo de sabiduría y protección. Gracias por cuidar de quienes amas.',
          'author': 'Con respeto y amor'
        };
        
      case 'paxolotl_baby':
        return {
          'message': 'Para PaoPao , gracias por ser lo mejor que me dejo la carrera , esto es gracias a ti',
          'author': 'Con admiración'
        };
      case 'paxolotl_young':
        return {
          'message': 'A mi querido Paxolotl, que me enseñas que ser diferente es un regalo, no una limitación.',
          'author': 'Tu amigo fiel'
        };
      case 'paxolotl_adult':
        return {
          'message': 'Para Paxolotl sabio, guardián de tradiciones ancestrales y símbolo de resistencia.',
          'author': 'Con orgullo mexicano'
        };
        
      case 'yami_baby':
        return {
          'message': 'Para mi poderosa Yami, que desde pequeña mostró la fuerza que la caracteriza.',
          'author': 'Con respeto'
        };
      case 'yami_young':
        return {
          'message': 'A Yami en crecimiento, recordándome que el poder viene de proteger a quienes amas.',
          'author': 'Tu protector'
        };
      case 'yami_adult':
        return {
          'message': 'Para Yami majestuosa, reina de la selva y de mi corazón. Tu fuerza me inspira cada día.',
          'author': 'Con devoción eterna'
        };
        
      default:
        return {
          'message': 'Para alguien muy especial que hace cada día una aventura llena de amor y alegría.',
          'author': 'Con todo mi cariño'
        };
    }
  }
  
  Color _getAnimalColor(CompanionType type) {
    switch (type) {
      case CompanionType.dexter:
        return Colors.brown[600]!;
      case CompanionType.elly:
        return Colors.green[600]!;
      case CompanionType.paxolotl:
        return Colors.cyan[600]!;
      case CompanionType.yami:
        return Colors.purple[600]!;
    }
  }
  
  IconData _getAnimalIcon(CompanionType type) {
    switch (type) {
      case CompanionType.dexter:
        return Icons.pets;
      case CompanionType.elly:
        return Icons.forest;
      case CompanionType.paxolotl:
        return Icons.water;
      case CompanionType.yami:
        return Icons.nature;
    }
  }
  
  String _getAnimalTitle(CompanionType type) {
    switch (type) {
      case CompanionType.dexter:
        return 'Chihuahua';
      case CompanionType.elly:
        return 'Panda Gigante';
      case CompanionType.paxolotl:
        return 'Ajolote Mexicano';
      case CompanionType.yami:
        return 'Jaguar';
    }
  }
  
  String _getAnimalSubtitle(CompanionType type) {
    switch (type) {
      case CompanionType.dexter:
        return 'El más pequeño con el corazón más grande';
      case CompanionType.elly:
        return 'Símbolo de paz y conservación';
      case CompanionType.paxolotl:
        return 'El regenerador de Xochimilco';
      case CompanionType.yami:
        return 'El rey de la selva americana';
    }
  }
}