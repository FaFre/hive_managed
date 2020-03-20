import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations/madob_setter.dart';
import '../entities/madob_property.dart';
import '../madob_generator_error.dart';
import 'accessor_helper.dart';

/// Generates a [MadobProperty] from a [Map] of getter and setter
class MadobPropertyGenerator {
  static const _madobSetterTypeChecker = TypeChecker.fromRuntime(MadobSetter);

  final Map<int, MethodElement> _setterList;
  final Map<int, PropertyAccessorElement> _getterList;

  void _checkValidReferenceType(PropertyAccessorElement element) {
    final interface = element.returnType as InterfaceType;
    final type = interface.typeArguments.first;

    if (type.isDartCoreBool ||
        type.isDartCoreDouble ||
        type.isDartCoreInt ||
        type.isDartCoreList ||
        type.isDartCoreMap ||
        type.isDartCoreNum ||
        type.isDartCoreObject ||
        type.isDartCoreSet ||
        type.isDartCoreString ||
        type.isDartCoreSymbol ||
        type.isDynamic ||
        type.isObject) {
      throw MadobGeneratorError(
          '${element.name} is a core type (${type.getDisplayString()})'
          ' which is invalid when as a referenced Madob type');
    }
  }

  /// Initialize [MadobPropertyGenerator] with a [Map] of getter and setter
  MadobPropertyGenerator(this._getterList, this._setterList)
      : assert(_getterList != null),
        assert(_setterList != null);

  /// Returns a [Map] of generated [MadobProperty]'s
  Map<int, MadobProperty> generatePropertyList() {
    final propertyMap = _getterList.map((key, value) {
      final setterAnnotation =
          _madobSetterTypeChecker.firstAnnotationOf(_setterList[key]);

      final reference = AccessorHelper.getFieldHiveReference(setterAnnotation);
      if (reference?.isNotEmpty == true) _checkValidReferenceType(value);

      return MapEntry(
          key, MadobProperty(value, referencedHiveObjectName: reference));
    });

    return propertyMap;
  }
}
