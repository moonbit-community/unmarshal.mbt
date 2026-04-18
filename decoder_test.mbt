///|
test {

  // ocaml 1 marshalled 
  let data : Bytes = [
    b'\x84', b'\x95', b'\xa6', b'\xbe', b'\x00', b'\x00', b'\x00', b'\x01', b'\x00',
    b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
    b'\x00', b'\x00', b'\x41',
  ]
  println(data[20:])
  let state = @unmarshal.Decoder::new(data)
  let (a, b) = state.decode()
  //TODO:upstream Tuple2 impl ToJson
  json_inspect((a, b), content=[
    {
      "magic": 2224400062,
      "data_len": 1,
      "num_objects": 0,
      "size_32": 0,
      "size_64": 0,
    },
    ["MInt", 1],
  ])
}
