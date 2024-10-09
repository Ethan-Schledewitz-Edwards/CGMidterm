using UnityEngine;

public class Controller : MonoBehaviour
{
    [SerializeField] private float moveSpeed = 10f;
    [SerializeField] private Vector3 startDir;
    [SerializeField] private Rigidbody rB;

    private void Update()
    {
        // move motorbike forward with W
        if (Input.GetKey("w"))
        {
            rB.AddForce(new Vector3(startDir.x, 0, 0) * moveSpeed * Time.deltaTime);
        }
    }

}
