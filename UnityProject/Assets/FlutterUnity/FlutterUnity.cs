using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;

public class FlutterUnity : MonoBehaviour
{
  [DllImport("FlutterUnity")]
  private static extern void SetTextureFromUnity(System.IntPtr texture, int w, int h);

  [DllImport("FlutterUnity")]
  private static extern IntPtr GetRenderEventFunc();

  [DllImport("FlutterUnity")]
  private static extern void StartFlutterEngine(string projectPath, string icudtlPath);

  [DllImport("FlutterUnity")]
  private static extern void SendPointerEvent(int phase, double x, double y);

  // Start is called before the first frame update
  IEnumerator Start()
  {
    Texture2D tex = new Texture2D(1024, 1024, TextureFormat.ARGB32, false);
    tex.filterMode = FilterMode.Point;
    tex.Apply();

    GetComponent<Renderer>().material.mainTexture = tex;
    SetTextureFromUnity(tex.GetNativeTexturePtr(), tex.width, tex.height);

    string projectPath = Path.Join(Application.streamingAssetsPath, "flutter_assets");
    string icudtlPath = Path.Join(Application.streamingAssetsPath, "icudtl.dat");
    StartFlutterEngine(projectPath, icudtlPath);

    yield return StartCoroutine(CallPluginAtEndOfFrames());
  }

  // Update is called once per frame
  void Update()
  {
    int mouseEvent = -1;
    if (Input.GetMouseButtonDown(0)) {
      mouseEvent = 2; // kDown
    }
    if (Input.GetMouseButtonUp(0)) {
      mouseEvent = 1; // kUp
    }
    if (mouseEvent >= 0) {
      Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
      RaycastHit hit;
      if (Physics.Raycast(ray, out hit)) {
        if (hit.collider == this.GetComponent<MeshCollider>()) {
          Vector3 localPoint = this.transform.InverseTransformPoint(hit.point);
          // 5 and 10 come from the geometry of the mesh.
          double flutterPointX = 1 - ((localPoint.x + 5.0) / 10.0);
          double flutterPointY = 1 - ((localPoint.z + 5.0) / 10.0);
          SendPointerEvent(mouseEvent, flutterPointX, flutterPointY);
        }
      }
    }
  }

  private IEnumerator CallPluginAtEndOfFrames()
  {
    while (true)
    {
      yield return new WaitForEndOfFrame();
      GL.IssuePluginEvent(GetRenderEventFunc(), 1);
    }
  }
}
