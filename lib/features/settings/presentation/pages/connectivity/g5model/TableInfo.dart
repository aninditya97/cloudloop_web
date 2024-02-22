/*
import 'dart:collection';
import 'package:reflectable/reflectable.dart';
import 'package:text/text.dart';

class TableInfo {
  Type mType;
  String mTableName;
  String mIdName = "Id";
  Map<Field, String> mColumnNames = LinkedHashMap<Field, String>();

  TableInfo(this.mType) {
    Table tableAnnotation =
    mType.metadata.firstWhere((meta) => meta is Table, orElse: () => null);
    if (tableAnnotation != null) {
      mTableName = tableAnnotation.name;
      mIdName = tableAnnotation.id;
    } else {
      mTableName = mType.toString();
    }

    Field idField = getIdField(mType);
    mColumnNames[idField] = mIdName;
    List<Field> fields =
    LinkedList<Field>(ReflectionUtils.getDeclaredColumnFields(mType));
    fields.reversed.forEach((field) {
      if (field.hasAnnotation(Column)) {
        Column columnAnnotation = field.getAnnotation(Column) as Column;
        String columnName = columnAnnotation.name;
        if (TextUtils.isEmpty(columnName)) {
          columnName = field.name;
        }
        mColumnNames[field] = columnName;
      }
    });
  }

  Type getType() {
    return mType;
  }

  String getTableName() {
    return mTableName;
  }

  String getIdName() {
    return mIdName;
  }

  Collection<Field> getFields() {
    return mColumnNames.keys;
  }

  String getColumnName(Field field) {
    return mColumnNames[field];
  }

  Field getIdField(Type type) {
    if (type == Model) {
      try {
        return type.getField("mId");
      } catch (NoSuchMethodError) {
        print("Impossible!");
      }
    } else if (type.superclass != null) {
      return getIdField(type.superclass);
    }

    return null;
  }
}


 */
/*
import 'package:reflectable/reflectable.dart';

class TableInfo {
  ClassMirror _classMirror;
  late String _tableName;
  String _idName = 'Id';
  Map<Symbol, String> _columnNames = <Symbol, String>{};

  TableInfo(this._classMirror) {
    // Get table annotation
    final tableAnnotation =
    _classMirror.metadata.firstWhere((m) => m.reflectee is Table,
        orElse: () => null)?.reflectee as Table;
    if (tableAnnotation != null) {
      _tableName = tableAnnotation.name;
      _idName = tableAnnotation.id;
    } else {
      _tableName = _classMirror.simpleName;
    }

    // Get column names
    _columnNames[Symbol(_idName)] = _idName;
    final columns = _classMirror.declarations.values
        .whereType<VariableMirror>()
        .where((v) => v.metadata.any((m) => m.reflectee is Column));
    for (final column in columns) {
      final columnAnnotation =
          column.metadata.firstWhere((m) => m.reflectee is Column).reflectee;
      final columnName = columnAnnotation.name ?? MirrorSystem.getName(column.simpleName);
      _columnNames[column.simpleName] = columnName;
    }
  }

  String get tableName => _tableName;

  String get idName => _idName;

  Map<Symbol, String> get columnNames => _columnNames;
}


 */

/*
import 'dart:collection';

import 'package:reflectable/reflectable.dart';

class YourReflectable extends Reflectable {
  const YourReflectable() : super(reflectable: true);
}

const yourReflectable = YourReflectable();

// Reflectable type of Field
var fieldType = yourReflectable.reflectType(Field);

class TableInfo {
  // ...
  Map<VariableMirror, String> mColumnNames = new LinkedHashMap();

  TableInfo(Class<? extends Model> type) {
  // ...
  List<Field> fields = new LinkedList(ReflectionUtils.getDeclaredColumnFields(type));
  Collections.reverse(fields);
  Iterator var5 = fields.iterator();

  while(var5.hasNext()) {
  Field field = (Field)var5.next();
  if (field.isAnnotationPresent(Column.class)) {
  Column columnAnnotation = (Column)field.getAnnotation(Column.class);
  String columnName = columnAnnotation.name();
  if (TextUtils.isEmpty(columnName)) {
  columnName = field.getName();
  }
  // Reflectable variable mirror of Field
  var fieldMirror = fieldType.declarations.values
      .firstWhere((dm) => dm.simpleName == Symbol(field.name));
  this.mColumnNames.put(fieldMirror, columnName);
  }
  }
  }

  Type getColumnName(VariableMirror variableMirror) {
    return (String)this.mColumnNames[variableMirror];
  }
}

 */
