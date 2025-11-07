using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

// このScriptは複数のLightControllerからアクセスを受けて対称とするObject(Material)およびShaderを返すものである。

public class ObjectContainer : UdonSharpBehaviour
{
    [Header("Controlled Objects")]
    [Space(10)]
    [SerializeField] private Light[] Lights;

    public MeshRenderer GetMeshRendererObject
    {
        get{ return this.GetComponent<MeshRenderer>(); }
    }

    public Light[] GetLights
    {
        get { return Lights; }
    }
}
