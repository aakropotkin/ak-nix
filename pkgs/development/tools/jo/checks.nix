{ jo, diffutils, runCommandNoCC }:
{

  object = runCommandNoCC "checks-object-${jo.name}" {
    expected = ''
      {
         "name": "jo",
         "n": 17,
         "parser": false
      }
    '';
    passAsFile = ["expected"];
  } ''
    PATH="''${PATH+$PATH:}${jo}/bin:${diffutils}/bin";
    jo -p name=jo n=17 parser=false 2>&1|tee "$out"
    diff -q "$out" "$expectedPath" 2>&1
  '';

  list = runCommandNoCC "checks-object-${jo.name}" {
    expected = ''
      [1,2,3,4,5,6,7,8,9,10]
    '';
    passAsFile = ["expected"];
  } ''
    PATH="''${PATH+$PATH:}${jo}/bin:${diffutils}/bin";
    seq 1 10|jo -a 2>&1|tee "$out"
    diff -q "$out" "$expectedPath" 2>&1
  '';

}
