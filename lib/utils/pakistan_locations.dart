import 'package:latlong2/latlong.dart';

class LocationArea {
  final String name;
  final LatLng center;
  final double defaultZoom;

  const LocationArea({
    required this.name,
    required this.center,
    this.defaultZoom = 13.0,
  });
}

class LocationCity {
  final String name;
  final LatLng center;
  final double defaultZoom;
  final List<LocationArea> areas;

  const LocationCity({
    required this.name,
    required this.center,
    this.defaultZoom = 11.0,
    required this.areas,
  });
}

class PakistanLocations {
  static const LatLng pakistanCenter = LatLng(30.3753, 69.3451);
  static const double pakistanZoom = 5.5;

  static final List<LocationCity> cities = [
    LocationCity(
      name: 'Karachi',
      center: const LatLng(24.8607, 67.0011),
      defaultZoom: 11.5,
      areas: [
        const LocationArea(
          name: 'Clifton & DHA',
          center: LatLng(24.8138, 67.0494),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Gulshan-e-Iqbal',
          center: LatLng(24.9180, 67.0971),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Gulistan-e-Jauhar',
          center: LatLng(24.9126, 67.1354),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'North Karachi',
          center: LatLng(24.9961, 67.0658),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'North Nazimabad',
          center: LatLng(24.9392, 67.0422),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Nazimabad & Liaquatabad',
          center: LatLng(24.9080, 67.0326),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Saddar & PECHS / Tariq Road',
          center: LatLng(24.8615, 67.0543),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Malir & Model Colony',
          center: LatLng(24.8967, 67.1896),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Korangi & Landhi',
          center: LatLng(24.8258, 67.1347),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Bahria Town Karachi',
          center: LatLng(25.0125, 67.3392),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Federal B Area / Gulberg',
          center: LatLng(24.9351, 67.0722),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'SITE & Orangi',
          center: LatLng(24.9023, 66.9934),
          defaultZoom: 13.5,
        ),
      ],
    ),
    LocationCity(
      name: 'Lahore',
      center: const LatLng(31.5204, 74.3587),
      defaultZoom: 11.5,
      areas: [
        const LocationArea(
          name: 'DHA Lahore & Cantt',
          center: LatLng(31.4786, 74.3827),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Gulberg & Model Town',
          center: LatLng(31.5056, 74.3417),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Johar Town & Wapda Town',
          center: LatLng(31.4697, 74.2728),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Bahria Town Lahore & Raiwind',
          center: LatLng(31.3653, 74.1802),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Mall Road & Anarkali',
          center: LatLng(31.5580, 74.3160),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Allama Iqbal Town',
          center: LatLng(31.5126, 74.2818),
          defaultZoom: 13.5,
        ),
      ],
    ),
    LocationCity(
      name: 'Islamabad',
      center: const LatLng(33.6844, 73.0479),
      defaultZoom: 12.0,
      areas: [
        const LocationArea(
          name: 'F Sectors (F-6, F-7, F-10, F-11)',
          center: LatLng(33.7199, 73.0456),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'G Sectors (G-9, G-10, G-11)',
          center: LatLng(33.6844, 73.0234),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'E & H Sectors',
          center: LatLng(33.7011, 72.9867),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Bahria Town Islamabad & DHA',
          center: LatLng(33.5350, 73.1250),
          defaultZoom: 13.5,
        ),
      ],
    ),
    LocationCity(
      name: 'Rawalpindi',
      center: const LatLng(33.5651, 73.0169),
      defaultZoom: 12.0,
      areas: [
        const LocationArea(
          name: 'Saddar & Cantt',
          center: LatLng(33.5932, 73.0543),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Satellite Town & Shamsabad',
          center: LatLng(33.6366, 73.0768),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Bahria Town Rawalpindi',
          center: LatLng(33.5186, 73.1094),
          defaultZoom: 13.5,
        ),
      ],
    ),
    LocationCity(
      name: 'Faisalabad',
      center: const LatLng(31.4504, 73.1350),
      defaultZoom: 12.0,
      areas: [
        const LocationArea(
          name: 'Clock Tower & City Center',
          center: LatLng(31.4187, 73.0791),
          defaultZoom: 13.5,
        ),
        const LocationArea(
          name: 'Madina Town & Peoples Colony',
          center: LatLng(31.4245, 73.1118),
          defaultZoom: 13.5,
        ),
      ],
    ),
    LocationCity(
      name: 'Multan',
      center: const LatLng(30.1575, 71.5249),
      defaultZoom: 12.0,
      areas: [
        const LocationArea(
          name: 'Cantt & Gulgasht Colony',
          center: LatLng(30.2212, 71.4921),
          defaultZoom: 13.5,
        ),
      ],
    ),
    LocationCity(
      name: 'Hyderabad',
      center: const LatLng(25.3960, 68.3578),
      defaultZoom: 12.0,
      areas: [
        const LocationArea(
          name: 'Latifabad & Qasimabad',
          center: LatLng(25.3852, 68.3412),
          defaultZoom: 13.5,
        ),
      ],
    ),
    LocationCity(
      name: 'Peshawar',
      center: const LatLng(34.0151, 71.5249),
      defaultZoom: 12.0,
      areas: [
        const LocationArea(
          name: 'Hayatabad & Cantt',
          center: LatLng(33.9926, 71.4398),
          defaultZoom: 13.5,
        ),
      ],
    ),
    LocationCity(
      name: 'Quetta',
      center: const LatLng(30.1798, 66.9750),
      defaultZoom: 12.0,
      areas: [
        const LocationArea(
          name: 'Cantt & Jinnah Town',
          center: LatLng(30.2012, 66.9921),
          defaultZoom: 13.5,
        ),
      ],
    ),
  ];
}
